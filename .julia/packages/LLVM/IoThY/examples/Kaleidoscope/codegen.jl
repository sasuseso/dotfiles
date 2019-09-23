mutable struct CodeGen
    ctx::LLVM.Context
    builder::LLVM.Builder
    current_scope::CurrentScope
    mod::LLVM.Module

    CodeGen(ctx::LLVM.Context) =
        new(
            ctx,
            LLVM.Builder(ctx),
            CurrentScope(),
            LLVM.Module("KaleidoscopeModule", ctx),
        )
end

current_scope(cg::CodeGen) = cg.current_scope
function new_scope(f, cg::CodeGen)
    open_scope!(current_scope(cg))
    f()
    pop!(current_scope(cg))
end
Base.show(io::IO, cg::CodeGen) = print(io, "CodeGen")

function create_entry_block_allocation(cg::CodeGen, fn::LLVM.Function, varname::String)
    local alloc
    LLVM.Builder(cg.ctx) do builder
        # Set the builder at the start of the function
        entry_block = LLVM.entry(fn)
        if isempty(LLVM.instructions(entry_block))
            LLVM.position!(builder, entry_block)
        else
            LLVM.position!(builder, first(LLVM.instructions(entry_block)))
        end
        alloc = LLVM.alloca!(builder, LLVM.DoubleType(cg.ctx), varname)
    end
    return alloc
end

function codegen(cg::CodeGen, expr::NumberExprAST)
    return LLVM.ConstantFP(LLVM.DoubleType(cg.ctx), expr.val)
end

function codegen(cg::CodeGen, expr::VariableExprAST)
    V = get(current_scope(cg), expr.name, nothing)
    V == nothing && error("did not find variable $(expr.name)")
    return LLVM.load!(cg.builder, V, expr.name)
end

function codegen(cg::CodeGen, expr::BinaryExprAST)
    if expr.op == Kinds.EQUAL
        var = expr.lhs
        if !(var isa VariableExprAST)
            error("destination of '=' must be a variable")
        end
        R = codegen(cg, expr.rhs)
        V = get(current_scope(cg), var.name, nothing)
        V == nothing && error("unknown variable name $(var.name)")
        LLVM.store!(cg.builder, R, V)
        return R
    end
    L = codegen(cg, expr.lhs)
    R = codegen(cg, expr.rhs)

    if expr.op == Kinds.PLUS
        return LLVM.fadd!(cg.builder, L, R, "addtmp")
    elseif expr.op == Kinds.MINUS
        return LLVM.fsub!(cg.builder, L, R, "subtmp")
    elseif expr.op == Kinds.STAR
        return LLVM.fmul!(cg.builder, L, R, "multmp")
    elseif expr.op == Kinds.SLASH
        return LLVM.fdiv!(cg.builder, L, R, "divtmp")
    elseif expr.op == Kinds.LESS
        L = LLVM.fcmp!(cg.builder, LLVM.API.LLVMRealOLT, L, R, "cmptmp")
        return LLVM.uitofp!(cg.builder, L, LLVM.DoubleType(cg.ctx), "booltmp")
    elseif expr.op == Kinds.GREATER
        L = LLVM.fcmp!(cg.builder, LLVM.API.LLVMRealOGT, L, R, "cmptmp")
        return LLVM.uitofp!(cg.builder, L, LLVM.DoubleType(cg.ctx), "booltmp")
    else
        error("Unhandled binary operator $(expr.op)")
    end
end

function codegen(cg::CodeGen, expr::CallExprAST)
    if !haskey(LLVM.functions(cg.mod), expr.callee)
        error("encountered undeclared function $(expr.callee)")        
    end
    func =  LLVM.functions(cg.mod)[expr.callee]

    if length(LLVM.parameters(func)) != length(expr.args)
        error("number of parameters mismatch")
    end

    args = LLVM.Value[]
    for v in expr.args
        push!(args, codegen(cg, v))
    end

    return LLVM.call!(cg.builder, func, args, "calltmp")
end

function codegen(cg::CodeGen, expr::PrototypeAST)
    if haskey(LLVM.functions(cg.mod), expr.name)
            error("existing function exists")
    end
    args = [LLVM.DoubleType(cg.ctx) for i in 1:length(expr.args)]
    func_type = LLVM.FunctionType(LLVM.DoubleType(cg.ctx), args)
    func = LLVM.Function(cg.mod, expr.name, func_type)
    LLVM.linkage!(func, LLVM.API.LLVMExternalLinkage)

    for (i, param) in enumerate(LLVM.parameters(func))
        LLVM.name!(param, expr.args[i])
    end
    return func
end

function codegen(cg::CodeGen, expr::FunctionAST)
    # create new function...
    the_function = codegen(cg, expr.proto)

    entry = LLVM.BasicBlock(the_function, "entry", cg.ctx)
    LLVM.position!(cg.builder, entry)

    new_scope(cg) do
        for (i, param) in enumerate(LLVM.parameters(the_function))
            argname = expr.proto.args[i]
            alloc = create_entry_block_allocation(cg, the_function, argname)
            LLVM.store!(cg.builder, param, alloc)
            current_scope(cg)[argname] = alloc
        end

        body = codegen(cg, expr.body)
        LLVM.ret!(cg.builder, body)
        LLVM.verify(the_function)
    end
    return the_function
end

function codegen(cg::CodeGen, expr::IfExprAST)
    func = LLVM.parent(LLVM.position(cg.builder))
    then = LLVM.BasicBlock(func, "then", cg.ctx)
    elsee = LLVM.BasicBlock(func, "else", cg.ctx)
    merge = LLVM.BasicBlock(func, "ifcont", cg.ctx)

    local phi
    new_scope(cg) do
        # if
        cond = codegen(cg, expr.cond)
        zero = LLVM.ConstantFP(LLVM.DoubleType(cg.ctx), 0.0)
        condv = LLVM.fcmp!(cg.builder, LLVM.API.LLVMRealONE, cond, zero, "ifcond")
        LLVM.br!(cg.builder, condv, then, elsee)

        # then
        LLVM.position!(cg.builder, then)
        thencg = codegen(cg, expr.then)
        LLVM.br!(cg.builder, merge)
        then_block = position(cg.builder)

        # else
        LLVM.position!(cg.builder, elsee)
        elsecg = codegen(cg, expr.elsee)
        LLVM.br!(cg.builder, merge)
        else_block = position(cg.builder)

        # merge
        LLVM.position!(cg.builder, merge)
        phi = LLVM.phi!(cg.builder, LLVM.DoubleType(cg.ctx), "iftmp")
        append!(LLVM.incoming(phi), [(thencg, then_block), (elsecg, else_block)])
    end

    return phi
end

function codegen(cg::CodeGen, expr::ForExprAST)
    new_scope(cg) do
        # Allocate loop variable
        startblock = position(cg.builder)
        func = LLVM.parent(startblock)
        alloc = create_entry_block_allocation(cg, func, expr.varname)
        current_scope(cg)[expr.varname] = alloc
        start = codegen(cg, expr.start)
        LLVM.store!(cg.builder, start, alloc)

        # Loop block
        loopblock = LLVM.BasicBlock(func, "loop", cg.ctx)
        LLVM.br!(cg.builder, loopblock)
        LLVM.position!(cg.builder, loopblock)

        # Code for loop block
        codegen(cg, expr.body)
        step = codegen(cg, expr.step)
        endd = codegen(cg, expr.endd)

        curvar = LLVM.load!(cg.builder, alloc, expr.varname)
        nextvar = LLVM.fadd!(cg.builder, curvar, step, "nextvar")
        LLVM.store!(cg.builder, nextvar, alloc)

        endd = LLVM.fcmp!(cg.builder, LLVM.API.LLVMRealONE, endd,
            LLVM.ConstantFP(LLVM.DoubleType(cg.ctx), 0.0))

        loopendblock = position(cg.builder)
        afterblock = LLVM.BasicBlock(func, "afterloop", cg.ctx)

        LLVM.br!(cg.builder, endd, loopblock, afterblock)
        LLVM.position!(cg.builder, afterblock)
    end

    # loops return 0.0 for now
    return LLVM.ConstantFP(LLVM.DoubleType(cg.ctx), 0.0)
end

function codegen(cg::CodeGen, expr::VarExprAST)
    local initval
    for (varname, init) in expr.varnames
        initval = codegen(cg, init)
        local V
        if isglobalscope(current_scope(cg))
            V = LLVM.GlobalVariable(cg.mod, LLVM.DoubleType(cg.ctx), varname)
            LLVM.initializer!(V, initval)
        else
            func = LLVM.parent(LLVM.position(cg.builder))
            V = create_entry_block_allocation(cg, func, varname)
            LLVM.store!(cg.builder, initval, V)
        end
        current_scope(cg)[varname] = V
    end
    return initval
end

function codegen(cg::CodeGen, block::BlockExprAST)
    local v
    new_scope(cg) do
        for expr in block.exprs
            v = codegen(cg, expr)
        end
    end
    return v
end
