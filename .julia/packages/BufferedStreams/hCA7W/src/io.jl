# IO
# --

function readbytes!(source::IO, buffer::AbstractArray{UInt8}, from::Int, to::Int)
    return Base.readbytes!(source, view(buffer, from:to), to - from + 1)
end

function writebytes(sink::IO, buffer::AbstractArray{UInt8}, n::Int, eof::Bool)
    return write(sink, view(buffer, 1:n))
end


# IOStream
# --------

function readbytes!(source::IOStream, buffer::AbstractArray{UInt8}, from::Int, to::Int)
    return Int(ccall(:ios_readall, UInt, (Ptr{Cvoid}, Ptr{Cvoid}, UInt), source.ios,
                     pointer(buffer, from), to - from + 1))
end

# TODO: using ios_write, but look into _os_write_all
#function Base.write(source::IOStream, buffer::Vector{UInt8}, n::Int)
#end
