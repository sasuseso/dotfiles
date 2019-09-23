export BasicBlock, unsafe_delete!,
       parent, terminator, name,
       move_before, move_after

@checked struct BasicBlock <: Value
    ref::reftype(Value)
end
identify(::Type{Value}, ::Val{API.LLVMBasicBlockValueKind}) = BasicBlock

# forward declarations
@checked struct Function <: GlobalObject
    ref::reftype(GlobalObject)
end

BasicBlock(ref::API.LLVMBasicBlockRef) = BasicBlock(API.LLVMBasicBlockAsValue(ref))
blockref(bb::BasicBlock) = API.LLVMValueAsBasicBlock(ref(bb))

BasicBlock(f::Function, name::String) = 
    BasicBlock(API.LLVMAppendBasicBlock(ref(f), name))
BasicBlock(f::Function, name::String, ctx::Context) = 
    BasicBlock(API.LLVMAppendBasicBlockInContext(ref(ctx), ref(f), name))
BasicBlock(bb::BasicBlock, name::String) = 
    BasicBlock(API.LLVMInsertBasicBlock(blockref(bb), name))
BasicBlock(bb::BasicBlock, name::String, ctx::Context) = 
    BasicBlock(API.LLVMInsertBasicBlockInContext(ref(ctx), blockref(bb), name))

unsafe_delete!(::Function, bb::BasicBlock) = API.LLVMDeleteBasicBlock(blockref(bb))
Base.delete!(::Function, bb::BasicBlock) =
    API.LLVMRemoveBasicBlockFromParent(blockref(bb))

parent(bb::BasicBlock) = Function(API.LLVMGetBasicBlockParent(blockref(bb)))

terminator(bb::BasicBlock) = Instruction(API.LLVMGetBasicBlockTerminator(blockref(bb)))

name(bb::BasicBlock) =
    unsafe_string(API.LLVMGetBasicBlockName(blockref(bb)))

move_before(bb::BasicBlock, pos::BasicBlock) =
    API.LLVMMoveBasicBlockBefore(blockref(bb), blockref(pos))
move_after(bb::BasicBlock, pos::BasicBlock) =
    API.LLVMMoveBasicBlockAfter(blockref(bb), blockref(pos))


## instruction iteration

export instructions

struct BasicBlockInstructionSet
    bb::BasicBlock
end

instructions(bb::BasicBlock) = BasicBlockInstructionSet(bb)

Base.eltype(::BasicBlockInstructionSet) = Instruction

function Base.iterate(iter::BasicBlockInstructionSet,
                      state=API.LLVMGetFirstInstruction(blockref(iter.bb)))
    state == C_NULL ? nothing : (Instruction(state), API.LLVMGetNextInstruction(state))
end

Base.last(iter::BasicBlockInstructionSet) =
    Instruction(API.LLVMGetLastInstruction(blockref(iter.bb)))

Base.isempty(iter::BasicBlockInstructionSet) =
    API.LLVMGetLastInstruction(blockref(iter.bb)) == C_NULL

Base.IteratorSize(::BasicBlockInstructionSet) = Base.SizeUnknown()
