from ctypes import *
import zlib
import sys
import lzma
import hashlib

# /*
#  * xar_header version 1
#  */
# struct xar_header {
#     uint32_t magic;	
#     uint16_t size;
#     uint16_t version;
#     uint64_t toc_length_compressed;
#     uint64_t toc_length_uncompressed;
#     uint32_t cksum_alg;
#     /* A nul-terminated, zero-padded to multiple of 4, message digest name
#      * appears here if cksum_alg is 3 which must not be empty ("") or "none".
#      */
# };
class xar_header(Structure):
    _pack_ = 1
    _fields_ = [
        ("magic", c_uint32),
        ("size", c_uint16),
        ("version", c_uint16),
        ("toc_length_compressed", c_uint64),
        ("toc_length_uncompressed", c_uint64),
        ("cksum_alg", c_uint32)
    ]

    def get_magic(self):
        return self.magic.to_bytes(4, byteorder="little").decode("utf-8")
    
    def get_version(self):
        return int.from_bytes(self.version.to_bytes(2, byteorder="little"))
    
    def get_size(self):
        return int.from_bytes(self.size.to_bytes(2, byteorder="little"))
    
    def get_cksum_alg(self):
        return int.from_bytes(self.cksum_alg.to_bytes(4, byteorder="little"))
    
    def get_toc_length_compressed(self):
        return int.from_bytes(self.toc_length_compressed.to_bytes(8, byteorder="little"))
    
    def get_toc_length_uncompressed(self):
        return int.from_bytes(self.toc_length_uncompressed.to_bytes(8, byteorder="little"))


def inflate(data):
    decompress = zlib.decompressobj()
    inflated = decompress.decompress(data)
    inflated += decompress.flush()
    return inflated

x = open("CLTools_macOSNMOS_SDK.pkg", "rb")

h = xar_header()
x.readinto(h)

# print(h.get_magic(), h.get_size(), h.get_version(), h.get_toc_length_compressed(), h.get_toc_length_uncompressed(), h.get_cksum_alg())

zz = x.read(h.get_toc_length_compressed())
zz = inflate(zz)
# print(zz)

x.seek(1497133, 1)

start = x.tell()
magic = x.read(4)
flags = int.from_bytes(x.read(8))

# sys.stdout.buffer.write(magic)
# sys.stdout.buffer.write(flags.to_bytes(8))

xz = lzma.LZMADecompressor()

XBSZ = 4 * 1024

ranges = []

while flags & 1 << 24:
    # print("flags", flags)
    flags = int.from_bytes(x.read(8))
    length = int.from_bytes(x.read(8))

    start = x.tell()
    # print(flags)
    # sys.stdout.buffer.write(flags.to_bytes(8))
    # sys.stdout.buffer.write(length.to_bytes(8))
    r = x.read(min(length, XBSZ))

    h = hashlib.sha256()

    while length:
        h.update(r)
        length -= min(length, XBSZ)
        sys.stdout.buffer.write(r)
        sys.stdout.buffer.flush()
        r = x.read(min(length, XBSZ))
      
    
    ranges.append((start, h.hexdigest()))
else:
    # We need to know the end to 
    ranges.append((x.tell() + 16, "end_of_stream"))

sys.stderr.write("ranges: %s\n" % ranges)