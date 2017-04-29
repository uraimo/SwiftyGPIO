import SwiftyGPIO //Remove this import if you are compiling manually with switfc
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif
import Foundation


// Xoroshiro random generator by @cocoawithlove
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


//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                    WS2812 Leds                                       //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////

let pwms = SwiftyGPIO.hardwarePWMs(for:.RaspberryPi2)!
let pwm = (pwms[0]?[.P18])!

// Initialize PWM
pwm.initPWM()


let PWM_CHANNELS = 1
let NUM_ELEMENTS = 64 //8x8 matrix, change this to what you want, but remember that different matrixes could have different connections between single leds
let WS2812_FREQ = 800000 // 800Khz
let WS2812_RESETDELAY = 55  // 55us reset

var xoro = Xoroshiro()

func toByteStream(_ values: [UInt32]) -> [UInt8]{
    var byteStream = [UInt8]()
    for led in values {
        //let scale: UInt8 = 1 //UInt8(led & 0xff) + 1
        // Add as GRB
        byteStream.append(UInt8((led >> UInt32(16))  & 0xff)) // * scale) >> 8)
        byteStream.append(UInt8((led >> UInt32(24)) & 0xff)) // * scale) >> 8)
        byteStream.append(UInt8((led >> UInt32(8))  & 0xff)) // * scale) >> 8)
    }
    return byteStream
}

func scroll(_ values: [UInt32]) -> [UInt32] {
    var arr = Array(values[1..<values.count])
    arr.append(values[0])
    return arr
}

// Matrix effects

func ledsRandom(_ values: [UInt32]) -> [UInt32] {
    var values = values
    for i in 0..<NUM_ELEMENTS {
        let r = UInt32(xoro.random64() % 254 + 1)
        let g = UInt32(xoro.random64() % 254 + 1)
        let b = UInt32(xoro.random64() % 254 + 1)
        values[i] = (r<<24) + (g<<16) + (b<<8) + UInt32(0x50) // R-G-B-L
    }
    return values
}

func ledsFill(_ values: [UInt32], color: UInt32) -> [UInt32] {
    var values = values
    for i in 0..<NUM_ELEMENTS {
        values[i] = color // R-G-B-L
    }
    return values
}

func ledsHalf(_ values: [UInt32], color: UInt32) -> [UInt32] {
    var values = values
    for i in 0..<NUM_ELEMENTS {
        values[i] = (i%2 == 0) ? color : 0// R-G-B-L
    }
    return values
}

func ledsSnake(_ values: [UInt32]) -> [UInt32] {
    var values = values
    values[0] = 0x00606050
    values[1] = 0x00404050
    values[2] = 0x00202050
    values[3] = 0x00002050
    values[4] = 0x00002050
    values[5] = 0x00002050
    return values
}

func ledsCosine(_ values: [UInt32], width: Int, time: Int) -> [UInt32] {
    var values = values
    for i in 0..<NUM_ELEMENTS {
        let center = Double(width/2) * 0.9
        let scale = 1.0 // Bigger = smaller period
        var ix = Double(i%width) - center
        ix *= scale
        var iy = Double(i/width) - center
        iy *= scale
        let cosarg = (sqrt(ix*ix+iy*iy) - Double(time))
        values[i] = UInt32( (cos(cosarg) + 1) * 100 + 10) << 8
    }
    return values
}

func ledsRipple(_ values: [UInt32], width: Int, time: Int) -> [UInt32] {
    var values = values
    let time = time % 50 // Repeat every 50 frames
    for i in 0..<NUM_ELEMENTS {
        let center = Double(width/2) * 0.9
        let scale = 3.5 //Bigger = smaller initial drop and thinner ripple
        var ix = Double(i%width) - center
        ix *= scale
        var iy = Double(i/width) - center
        iy *= scale
        let timeDiv = 0.7 //Smaller = slower
        let cosarg = (sqrt(ix*ix+iy*iy) - Double(time)*timeDiv)
        // Use the cardinal sine function sinc(x) -> sin(x)/x [0.2,1]
        values[i] = UInt32( sin(cosarg)/cosarg * 180 + 50) << 8
    }
    return values
}


func ledsRainbow(_ values: [UInt32], width: Int, time: Int) -> [UInt32] {
    let colors:[UInt32] = [0x20000000,0x20100000,0x20200000,0x00200000,0x00202000,0x00002000,0x10001000,0x20001000]
    var values = values
    for i in 0..<NUM_ELEMENTS {
        values[i] = colors[(i%width + time)%colors.count]
    }
    return values
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Initialize the PWM bit-pattern signal generator
// 3 bytes (GBR, yes, GBR), 55us reset time and 800khz frequency, 0= 33us, 1= 66us ... allowed by the led driver tollerance
pwm.initPWMPattern(bytes: NUM_ELEMENTS*3, at: WS2812_FREQ, with: WS2812_RESETDELAY, dutyzero: 33, dutyone: 66) 

// Send some data

var initial = [UInt32](repeating:0x0, count:NUM_ELEMENTS)
var byteStream: [UInt8] = toByteStream(initial)

var leds: [UInt32] = ledsRandom(initial)
for i in 0...100 {
    pwm.sendDataWithPattern(values: byteStream)
    leds = ledsRandom(leds)
    byteStream = toByteStream(leds)
}

leds = ledsRainbow(initial, width: 8, time: 0)
for i in 0...100 {
    pwm.sendDataWithPattern(values: byteStream)
    leds = ledsRainbow(leds, width: 8, time: i)
    usleep(50_000)
    byteStream = toByteStream(leds)
}

leds = ledsSnake(initial)
for i in 0...200 {
    pwm.sendDataWithPattern(values: byteStream)
    leds = scroll(leds)
    byteStream = toByteStream(leds)
}

leds = ledsCosine(initial, width: 8, time: 0)
for i in 0...200 {
    pwm.sendDataWithPattern(values: byteStream)
    leds = ledsCosine(leds, width: 8, time: i)
    usleep(50_000)
    byteStream = toByteStream(leds)
}

leds = ledsRipple(initial, width: 8, time: 0)
for i in 0...200 {
    pwm.sendDataWithPattern(values: byteStream)
    leds = ledsRipple(leds, width: 8, time: i)
    byteStream = toByteStream(leds)
}

//Clear matrix
byteStream = toByteStream(initial)
pwm.sendDataWithPattern(values: byteStream)


// Wait for the transmission to end
pwm.waitOnSendData()

// Clean up once you are done with the generator
pwm.cleanupPattern()

