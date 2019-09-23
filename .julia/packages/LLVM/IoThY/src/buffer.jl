export MemoryBuffer, MemoryBufferFile, dispose

@checked struct MemoryBuffer
    ref::API.LLVMMemoryBufferRef
end
reftype(::Type{MemoryBuffer}) = API.LLVMMemoryBufferRef

function MemoryBuffer(data::Vector{T}, name::String="", copy::Core.Bool=true) where T<:Union{UInt8,Int8}
    ptr = pointer(data)
    len = Csize_t(length(data))
    if copy
        return MemoryBuffer(API.LLVMCreateMemoryBufferWithMemoryRangeCopy(ptr, len, name))
    else
        return MemoryBuffer(API.LLVMCreateMemoryBufferWithMemoryRange(ptr, len, name,
                                                                      convert(Bool, false)))
    end
end

function MemoryBuffer(f::Core.Function, args...)
    membuf = MemoryBuffer(args...)
    try
        f(membuf)
    finally
        dispose(membuf)
    end
end

function MemoryBufferFile(path::String)
    out_ref = Ref{API.LLVMMemoryBufferRef}()

    out_error = Ref{Cstring}()
    status =
        convert(Core.Bool, API.LLVMCreateMemoryBufferWithContentsOfFile(path, out_ref, out_error))

    if status
        error = unsafe_string(out_error[])
        API.LLVMDisposeMessage(out_error[])
        throw(LLVMException(error))
    end

    MemoryBuffer(out_ref[])
end

function MemoryBufferFile(f::Core.Function, args...)
    membuf = MemoryBufferFile(args...)
    try
        f(membuf)
    finally
        dispose(membuf)
    end
end

dispose(membuf::MemoryBuffer) = API.LLVMDisposeMemoryBuffer(ref(membuf))

Base.length(membuf::MemoryBuffer) = API.LLVMGetBufferSize(ref(membuf))

Base.pointer(membuf::MemoryBuffer) = convert(Ptr{UInt8}, API.LLVMGetBufferStart(ref(membuf)))

Base.convert(::Type{Vector{UInt8}}, membuf::MemoryBuffer) =
    unsafe_wrap(Array, pointer(membuf), length(membuf))
