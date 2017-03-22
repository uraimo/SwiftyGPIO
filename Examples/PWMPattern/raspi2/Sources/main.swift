#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif


// From: https://github.com/mattgallagher/CwlUtils/blob/master/Sources/CwlUtils/CwlRandom.swift
public struct DevRandom {
    class FileDescriptor {
        let value: CInt
        init() {
            value = open("/dev/urandom", O_RDONLY)
            precondition(value >= 0)
        }
        deinit {
            close(value)
        }
    }
    
    let fd: FileDescriptor
    public init() {
        fd = FileDescriptor()
    }
    
    public mutating func randomize(buffer: UnsafeMutableRawPointer, size: Int) {
        let result = read(fd.value, buffer, size)
        precondition(result == size)
    }
    
    public static func randomize(buffer: UnsafeMutableRawPointer, size: Int) {
        var r = DevRandom()
        r.randomize(buffer: buffer, size: size)
    }
}

public struct Xoroshiro {
    public typealias WordType = UInt64
    public typealias StateType = (UInt64, UInt64)

    var state: StateType = (0, 0)

    public init() {
        DevRandom.randomize(buffer: &state, size: MemoryLayout<StateType>.size)
    }
    
    public init(seed: StateType) {
        self.state = seed
    }
    
    public mutating func random64() -> UInt64 {
        return randomWord()
    }

    public mutating func randomWord() -> UInt64 {
        // Directly inspired by public domain implementation here:
        // http://xoroshiro.di.unimi.it
        // by David Blackman and Sebastiano Vigna
        let (l, k0, k1, k2): (UInt64, UInt64, UInt64, UInt64) = (64, 55, 14, 36)
        
        let result = state.0 &+ state.1
        let x = state.0 ^ state.1
        state.0 = ((state.0 << k0) | (state.0 >> (l - k0))) ^ x ^ (x << k1)
        state.1 = (x << k2) | (x >> (l - k2))
        return result
    }
}


///////////////////////////////////////


let pwms = SwiftyGPIO.hardwarePWMs(for:.RaspberryPi2)!
let pwm = (pwms[0]?[.P18])!

// Initialize PWM
pwm.initPWM()

/////////////Render to strip 
// Possible color values: 16x16
let ws281x_gamma: [UInt8] = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2,
2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5,
6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 11, 11,
11, 12, 12, 13, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18,
19, 19, 20, 21, 21, 22, 22, 23, 23, 24, 25, 25, 26, 27, 27, 28,
29, 29, 30, 31, 31, 32, 33, 34, 34, 35, 36, 37, 37, 38, 39, 40,
40, 41, 42, 43, 44, 45, 46, 46, 47, 48, 49, 50, 51, 52, 53, 54,
55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70,
71, 72, 73, 74, 76, 77, 78, 79, 80, 81, 83, 84, 85, 86, 88, 89,
90, 91, 93, 94, 95, 96, 98, 99, 100, 102, 103, 104, 106, 107, 109, 110,
111, 113, 114, 116, 117, 119, 120, 121, 123, 124, 126, 128, 129, 131, 132, 134,
135, 137, 138, 140, 142, 143, 145, 146, 148, 150, 151, 153, 155, 157, 158, 160,
162, 163, 165, 167, 169, 170, 172, 174, 176, 178, 179, 181, 183, 185, 187, 189,
191, 193, 194, 196, 198, 200, 202, 204, 206, 208, 210, 212, 214, 216, 218, 220,
222, 224, 227, 229, 231, 233, 235, 237, 239, 241, 244, 246, 248, 250, 252, 255]


let PWM_CHANNELS = 1
let NUM_ELEMENTS = 60
let WS2812_FREQ = 800000 // 800Khz
let WS2812_RESETDELAY = 55  // 55us reset

var xoro = Xoroshiro()

func ledsRandom() -> [UInt32] {
    var a = [UInt32](repeating:0x0, count:NUM_ELEMENTS)
    for i in 0..<NUM_ELEMENTS {
        let r = UInt32(xoro.random64() % 254 + 1)
        let g = UInt32(xoro.random64() % 254 + 1)
        let b = UInt32(xoro.random64() % 254 + 1)
        a[i] = (r<<24) + (g<<16) + (b<<8) + UInt32(0x50) // R-G-B-L
    }
    return a
}

func ledsOne() -> [UInt32] {
    var a = [UInt32](repeating:0x0, count:NUM_ELEMENTS)
    for i in 0..<NUM_ELEMENTS {
        a[i] = 0x50505050 // R-G-B-L
    }
    return a
}

func ledsHalf() -> [UInt32] {
    var a = [UInt32](repeating:0x0, count:NUM_ELEMENTS)
    for i in 0..<NUM_ELEMENTS {
        a[i] = (i%2 == 0) ? 0x50505050 : 0// R-G-B-L
    }
    return a
}

func ledsSnake() -> [UInt32] {
    var a = [UInt32](repeating:0x0, count:NUM_ELEMENTS)
    a[0] = 0x00606050
    a[1] = 0x00404050
    a[2] = 0x00202050
    a[3] = 0x00002050
    a[4] = 0x00002050
    a[5] = 0x00002050
    return a
}

var leds: [UInt32] = ledsSnake()

var byteStream = [UInt8]()

for led in leds {
    let scale: UInt8 = 1 //UInt8(led & 0xff) + 1
    // Add as GRB
    byteStream.append(ws281x_gamma[Int(led >> UInt32(16))  & 0xff]) // * scale) >> 8)
    byteStream.append(ws281x_gamma[Int(led >> UInt32(24)) & 0xff]) // * scale) >> 8)
    byteStream.append(ws281x_gamma[Int(led >> UInt32(8))  & 0xff]) // * scale) >> 8)
}

func scroll(_ values: [UInt8]) -> [UInt8] {
    var arr = Array(values[3..<values.count])
    arr.append(values[0])
    arr.append(values[1])
    arr.append(values[2])
    return arr
}

// Initialize the PWM bit-pattern signal generator
pwm.initPWMPattern(bytes: NUM_ELEMENTS*3, at: WS2812_FREQ, with: WS2812_RESETDELAY, dutyzero: 33, dutyone: 66) 

// Send some data
for i in 0...10000 {
    pwm.sendDataWithPattern(values: byteStream)
    byteStream = scroll(byteStream)
}

// Wait for the transmission to end
pwm.waitOnSendData()

// Clean up once you are done with the generator
pwm.cleanupPattern()

