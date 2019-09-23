function generate_IR(str, ctx::LLVM.Context=LLVM.GlobalContext())
    cg = CodeGen(ctx)
    ps = Parser(str)
    while true
        tok = current_token(ps)
        if tok.kind == Kinds.EOF
            break
        else
            r = ParseTopLevelExpr(ps)
            codegen(cg, r)
        end
    end
    LLVM.verify(cg.mod)
    LLVM.dispose(cg.builder)
    return cg.mod
end

function optimize!(mod::LLVM.Module)
    LLVM.ModulePassManager() do pass_manager
        LLVM.instruction_combining!(pass_manager)
        LLVM.reassociate!(pass_manager)
        LLVM.gvn!(pass_manager)
        LLVM.cfgsimplification!(pass_manager)
        LLVM.promote_memory_to_register!(pass_manager)
        LLVM.run!(pass_manager, mod)
    end
    return mod
end

function run(mod::LLVM.Module, entry::String)
    res_jl = 0.0
    LLVM.JIT(mod) do engine
        if !haskey(LLVM.functions(engine), entry)
            error("did not find entry function '$entry' in module")
        end
        f = LLVM.functions(engine)[entry]
        res = LLVM.run(engine, f)
        res_jl = convert(Float64, res, LLVM.DoubleType())
        LLVM.dispose(res)
    end
    return res_jl
end

function write_objectfile(mod::LLVM.Module, path::String)
    host_triple = Sys.MACHINE # LLVM.triple() might be wrong (see LLVM.jl#108)
    host_t = LLVM.Target(host_triple)
    LLVM.TargetMachine(host_t, host_triple) do tm
        LLVM.emit(tm, mod, LLVM.API.LLVMObjectFile, path)
    end
end
