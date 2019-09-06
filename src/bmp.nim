import streams
import strformat

type Image*[T] = ref object of RootObj
    data*: seq[T]
    width: int
    height: int


proc `[]=`*(i: Image, x, y: int, val: Image.T) =
    i.data[y * i.width + x] = val

proc `[]`*(i: Image, x, y: int): Image.T =
    i.data[y * i.width + x]

proc `mget`*(i: Image, x, y: int): var Image.T =
    i.data[y * i.width + x]

iterator mitems*(i: Image): (int, int, var Image.T) =
    yield (0, 0, i.mget(0, 0))


proc newImage*[T](height, width: int): Image[T] =
    new(result)
    result.height = height
    result.width = width
    result.data = newSeq[T](height * width)


proc save*(image: Image, stream: Stream) =

    let
        bitsPerPixel = 24
        bmpHeaderSz = 14
        dbiHeaderSz = 12
        gap1Sz = 32 - ((bmpHeaderSz + dbiHeaderSz) mod 32)
        pixelArrayOffset = bmpHeaderSz + dbiHeaderSz + gap1Sz
        rowSz = (bitsPerPixel * image.width + 31) div 32 * 4
        pixelArraySz = rowSz * image.height
        bmpSz = pixelArraySz + pixelArrayOffset

    # echo &"px ar offset: {pixelArrayOffset}"
    # echo &"rowSz: {rowSz}"
    # echo &"bmpSz: {bmpSz}"


    # write file header (14 bytes)
    stream.write(['B', 'M'])
    stream.write(uint32(bmpSz)) # size of bitmap file in bytes (4 bytes)
    stream.write(0'u16) # 2 reserved bytes
    stream.write(0'u16) # 2 reserved bytes
    stream.write(uint32(pixelArrayOffset)) # 4 byte offset where pixel array is
    assert stream.getPosition() == bmpHeaderSz

    # write DBI header
    # BITMAPCOREHEADER, 12 bytes
    stream.write(dbiHeaderSz.uint32) # size of header
    stream.write(image.width.uint16) # width in pixels
    stream.write(image.height.uint16) # height in pixels
    stream.write(1'u16) # number of color planes (must be 1)
    stream.write(bitsPerPixel.uint16) # 2 bytes bits per pixel
    assert stream.getPosition() == bmpHeaderSz + dbiHeaderSz

    # write extra bit masks

    # write color table
    # mandatory for color depths <= 8
    assert bitsPerPixel > 8

    # write gap to align pixel array
    for i in 0 ..< gap1Sz:
        stream.write(0'u8)


    # write pixel array
    assert stream.getPosition() == pixelArrayOffset
    for row in countdown(image.height - 1, 0):
        # echo &"write row {row}"
        var rowBytes = newSeq[byte]()
        for col in 0 ..< image.width:
            let color = image.data[row * image.width + col]
            rowBytes.add(color.uint8)
            rowBytes.add(color.uint8)
            rowBytes.add(color.uint8)
        while rowBytes.len < rowSz:
            rowBytes.add(0)
        assert rowBytes.len == rowSz
        # echo &"len {rowBytes.len}"
        stream.writeData(unsafeAddr rowBytes[0], rowBytes.len)
        # echo &"{stream.getPosition()}"

    # echo &"{stream.getPosition()}"
    assert stream.getPosition() == bmpSz
    # write gap to align ICC color profile

    # write ICC color profile



when isMainModule:
    var img = newImage[uint8](1000, 1000)
    img[0, 0] = 255'u8
    img[0, 1] = 127'u8

    var s = openFileStream("test.bmp", fmWrite)

    img.save(s)

    s.close()
