/*
 SwiftyGPIO

 Copyright (c) 2016 Umberto Raimondi
 Licensed under the MIT license, as follows:

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.)
 */

// MARK: - GPIOs Presets
extension SwiftyGPIO {
    // RaspberryPi A and B Revision 1 (Before September 2012) - 26 pin header boards
    // 0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25
    static let GPIORPIRev1: [GPIOName:GPIO] = [
        .pin0: RaspberryGPIO(id:0),
        .pin1: RaspberryGPIO(id:1),
        .pin4: RaspberryGPIO(id:4),
        .pin7: RaspberryGPIO(id:7),
        .pin8: RaspberryGPIO(id:8),
        .pin9: RaspberryGPIO(id:9),
        .pin10: RaspberryGPIO(id:10),
        .pin11: RaspberryGPIO(id:11),
        .pin14: RaspberryGPIO(id:14),
        .pin15: RaspberryGPIO(id:15),
        .pin17: RaspberryGPIO(id:17),
        .pin18: RaspberryGPIO(id:18),
        .pin21: RaspberryGPIO(id:21),
        .pin22: RaspberryGPIO(id:22),
        .pin23: RaspberryGPIO(id:23),
        .pin24: RaspberryGPIO(id:24),
        .pin25: RaspberryGPIO(id:25)
    ]

    // RaspberryPi A and B Revision 2 (After September 2012) - 26 pin header boards
    //TODO: Additional GPIO from 28-31 ignored for now
    // 2, 3, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 22, 23, 24, 25, 27
    static let GPIORPIRev2: [GPIOName:GPIO] = [
        .pin2: RaspberryGPIO(id:2),
        .pin3: RaspberryGPIO(id:3),
        .pin4: RaspberryGPIO(id:4),
        .pin7: RaspberryGPIO(id:7),
        .pin8: RaspberryGPIO(id:8),
        .pin9: RaspberryGPIO(id:9),
        .pin10: RaspberryGPIO(id:10),
        .pin11: RaspberryGPIO(id:11),
        .pin14: RaspberryGPIO(id:14),
        .pin15: RaspberryGPIO(id:15),
        .pin17: RaspberryGPIO(id:17),
        .pin18: RaspberryGPIO(id:18),
        .pin22: RaspberryGPIO(id:22),
        .pin23: RaspberryGPIO(id:23),
        .pin24: RaspberryGPIO(id:24),
        .pin25: RaspberryGPIO(id:25),
        .pin27: RaspberryGPIO(id:27)
    ]

    // RaspberryPi A+ and B+, Raspberry Zero - 40 pin header boards
    // 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
    static let GPIORPIPlusZERO: [GPIOName:GPIO] = [
        .pin2: RaspberryGPIO(id:2),
        .pin3: RaspberryGPIO(id:3),
        .pin4: RaspberryGPIO(id:4),
        .pin5: RaspberryGPIO(id:5),
        .pin6: RaspberryGPIO(id:6),
        .pin7: RaspberryGPIO(id:7),
        .pin8: RaspberryGPIO(id:8),
        .pin9: RaspberryGPIO(id:9),
        .pin10: RaspberryGPIO(id:10),
        .pin11: RaspberryGPIO(id:11),
        .pin12: RaspberryGPIO(id:12),
        .pin13: RaspberryGPIO(id:13),
        .pin14: RaspberryGPIO(id:14),
        .pin15: RaspberryGPIO(id:15),
        .pin16: RaspberryGPIO(id:16),
        .pin17: RaspberryGPIO(id:17),
        .pin18: RaspberryGPIO(id:18),
        .pin19: RaspberryGPIO(id:19),
        .pin20: RaspberryGPIO(id:20),
        .pin21: RaspberryGPIO(id:21),
        .pin22: RaspberryGPIO(id:22),
        .pin23: RaspberryGPIO(id:23),
        .pin24: RaspberryGPIO(id:24),
        .pin25: RaspberryGPIO(id:25),
        .pin26: RaspberryGPIO(id:26),
        .pin27: RaspberryGPIO(id:27)
    ]

    // RaspberryPi 2
    // 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
    static let GPIORPI2: [GPIOName:GPIO] = [
        .pin2: RaspberryGPIO(id:2),
        .pin3: RaspberryGPIO(id:3),
        .pin4: RaspberryGPIO(id:4),
        .pin5: RaspberryGPIO(id:5),
        .pin6: RaspberryGPIO(id:6),
        .pin7: RaspberryGPIO(id:7),
        .pin8: RaspberryGPIO(id:8),
        .pin9: RaspberryGPIO(id:9),
        .pin10: RaspberryGPIO(id:10),
        .pin11: RaspberryGPIO(id:11),
        .pin12: RaspberryGPIO(id:12),
        .pin13: RaspberryGPIO(id:13),
        .pin14: RaspberryGPIO(id:14),
        .pin15: RaspberryGPIO(id:15),
        .pin16: RaspberryGPIO(id:16),
        .pin17: RaspberryGPIO(id:17),
        .pin18: RaspberryGPIO(id:18),
        .pin19: RaspberryGPIO(id:19),
        .pin20: RaspberryGPIO(id:20),
        .pin21: RaspberryGPIO(id:21),
        .pin22: RaspberryGPIO(id:22),
        .pin23: RaspberryGPIO(id:23),
        .pin24: RaspberryGPIO(id:24),
        .pin25: RaspberryGPIO(id:25),
        .pin26: RaspberryGPIO(id:26),
        .pin27: RaspberryGPIO(id:27)
    ]

    // C.H.I.pin.
    // Pins XIO-P0 to P7 linearly map to:
    // kernel 4.3: gpio408 to gpio415
    // kernel 4.4.11: gpio1016 to gpio1023 
    // kernel 4.4.13-ntc-mlc: gpio1013 to gpio 1020 (latest, available since december 2016)
    //
    // See: https://docs.getchip.com/chip.html#kernel-4-3-vs-4-4-gpio-how-to-tell-the-difference
    static let GPIOCHIP: [GPIOName:GPIO] = [
        .pin0: GPIO(name:"XIO-P0", id:1013),
        .pin1: GPIO(name:"XIO-P1", id:1014),
        .pin2: GPIO(name:"XIO-P2", id:1015),
        .pin3: GPIO(name:"XIO-P3", id:1016),
        .pin4: GPIO(name:"XIO-P4", id:1017),
        .pin5: GPIO(name:"XIO-P5", id:1018),
        .pin6: GPIO(name:"XIO-P6", id:1019),
        .pin7: GPIO(name:"XIO-P7", id:1020),
        .pin8: GPIO(name:"LCD_D2", id:98), //LCD pins (PDn pins on AllWinner doc) are calculated with 32*(PD=3) + id
        .pin9: GPIO(name:"LCD_D3", id:99),
        .pin10: GPIO(name:"LCD_D4", id:100),
        .pin11: GPIO(name:"LCD_D5", id:101),
        .pin12: GPIO(name:"LCD_D6", id:102),
        .pin13: GPIO(name:"LCD_D7", id:103),
        .pin14: GPIO(name:"LCD_D8", id:104),
        .pin15: GPIO(name:"LCD_D9", id:105),
        .pin16: GPIO(name:"LCD_D10", id:106),
        .pin17: GPIO(name:"LCD_D11", id:107),
        .pin18: GPIO(name:"LCD_D12", id:108),
        .pin19: GPIO(name:"LCD_D13", id:109),
        .pin20: GPIO(name:"LCD_D14", id:110),
        .pin21: GPIO(name:"LCD_D15", id:111),
        .pin22: GPIO(name:"LCD_D16", id:112),
        .pin23: GPIO(name:"LCD_D17", id:113),
        .pin24: GPIO(name:"LCD_D18", id:114),
        .pin25: GPIO(name:"LCD_D19", id:115),
        .pin26: GPIO(name:"LCD_D20", id:116),
        .pin27: GPIO(name:"LCD_D21", id:117),
        .pin28: GPIO(name:"LCD_D22", id:118),
        .pin29: GPIO(name:"LCD_D23", id:119),
        .pin30: GPIO(name:"LCD_D24", id:120),
        .pin31: GPIO(name:"LCD_D25", id:121),
        .pin32: GPIO(name:"LCD_D26", id:122),
        .pin33: GPIO(name:"LCD_D27", id:123)
    ]

    //BeagleBoneBlack
    //
    //The gpio id is the sum of the related gpio controller base number
    //and the progressive id of the gpio within its group...
    //The key of the map is assigned sequentially following the orders of
    //the pins, and i realize it could not be that useful(likely to change
    //in the future in favor of a better alternative).
    //
    //Only the pins described as gpio in the official documentation are
    //included here: https://github.com/CircuitCo/BeagleBone-Black/blob/master/BBB_SRM.pindf?raw=true
    //Clearly this does not support mode change.
    //
    static let GPIOBEAGLEBONE: [GPIOName:GPIO] = [
        .pin0: GPIO(name:"P8_PIN03_GPIO1_6", id:38),  //P8
        .pin1: GPIO(name:"P8_PIN04_GPIO1_7", id:39),
        .pin2: GPIO(name:"P8_PIN05_GPIO1_2", id:34),
        .pin3: GPIO(name:"P8_PIN06_GPIO1_3", id:35),
        .pin4: GPIO(name:"P8_PIN11_GPIO1_13", id:45),
        .pin5: GPIO(name:"P8_PIN12_GPIO1_12", id:44),
        .pin6: GPIO(name:"P8_PIN14_GPIO0_26", id:26),
        .pin7: GPIO(name:"P8_PIN15_GPIO1_15", id:47),
        .pin8: GPIO(name:"P8_PIN16_GPIO1_14", id:46),
        .pin9: GPIO(name:"P8_PIN17_GPIO0_27", id:27),
        .pin10: GPIO(name:"P8_PIN18_GPIO2_1", id:65),
        .pin11: GPIO(name:"P8_PIN20_GPIO1_31", id:63),
        .pin12: GPIO(name:"P8_PIN21_GPIO1_30", id:62),
        .pin13: GPIO(name:"P8_PIN22_GPIO1_5", id:37),
        .pin14: GPIO(name:"P8_PIN23_GPIO1_4", id:36),
        .pin15: GPIO(name:"P8_PIN24_GPIO1_1", id:33),
        .pin16: GPIO(name:"P8_PIN25_GPIO1_0", id:32),
        .pin17: GPIO(name:"P8_PIN26_GPIO1_29", id:61),
        .pin18: GPIO(name:"P8_PIN27_GPIO2_22", id:86),
        .pin19: GPIO(name:"P8_PIN28_GPIO2_24", id:88),
        .pin20: GPIO(name:"P8_PIN29_GPIO2_23", id:87),
        .pin21: GPIO(name:"P8_PIN30_GPIO2_25", id:89),
        .pin22: GPIO(name:"P8_PIN39_GPIO2_12", id:76),
        .pin23: GPIO(name:"P8_PIN40_GPIO2_13", id:77),
        .pin24: GPIO(name:"P8_PIN41_GPIO2_10", id:74),
        .pin25: GPIO(name:"P8_PIN42_GPIO2_11", id:75),
        .pin26: GPIO(name:"P8_PIN43_GPIO2_8", id:72),
        .pin27: GPIO(name:"P8_PIN44_GPIO2_9", id:73),
        .pin28: GPIO(name:"P8_PIN45_GPIO2_6", id:70),
        .pin29: GPIO(name:"P8_PIN46_GPIO2_7", id:71),
        .pin30: GPIO(name:"P9_PIN12_GPIO1_28", id:60),   //P9
        .pin31: GPIO(name:"P9_PIN15_GPIO1_16", id:48),
        .pin32: GPIO(name:"P9_PIN23_GPIO1_17", id:49),   //Ignore Pin25, requires oscillator disabled
        .pin33: GPIO(name:"P9_PIN27_GPIO3_19", id:125)
    ]

    // OrangePi
    // The pins are ordered by name: A0-A21(P0-P16), C0-C7(P17-P22), D14(P23), G6-G9(P24-P27)
    static let GPIOORANGEPI: [GPIOName:GPIO] = [
        .pin0: GPIO(sunXi:SunXiGPIO(letter: .A, pin:0)),
        .pin1: GPIO(sunXi:SunXiGPIO(letter:.A, pin:1)),
        .pin2: GPIO(sunXi:SunXiGPIO(letter:.A, pin:2)),
        .pin3: GPIO(sunXi:SunXiGPIO(letter:.A, pin:3)),
        .pin4: GPIO(sunXi:SunXiGPIO(letter:.A, pin:6)),
        .pin5: GPIO(sunXi:SunXiGPIO(letter:.A, pin:7)),
        .pin6: GPIO(sunXi:SunXiGPIO(letter:.A, pin:8)),
        .pin7: GPIO(sunXi:SunXiGPIO(letter:.A, pin:9)),
        .pin8: GPIO(sunXi:SunXiGPIO(letter:.A, pin:10)),
        .pin9: GPIO(sunXi:SunXiGPIO(letter:.A, pin:11)),
        .pin10: GPIO(sunXi:SunXiGPIO(letter:.A, pin:12)),
        .pin11: GPIO(sunXi:SunXiGPIO(letter:.A, pin:13)),
        .pin12: GPIO(sunXi:SunXiGPIO(letter:.A, pin:14)),
        .pin13: GPIO(sunXi:SunXiGPIO(letter:.A, pin:18)),
        .pin14: GPIO(sunXi:SunXiGPIO(letter:.A, pin:19)),
        .pin15: GPIO(sunXi:SunXiGPIO(letter:.A, pin:20)),
        .pin16: GPIO(sunXi:SunXiGPIO(letter:.A, pin:21)),
        .pin17: GPIO(sunXi:SunXiGPIO(letter:.C, pin:0)),
        .pin18: GPIO(sunXi:SunXiGPIO(letter:.C, pin:1)),
        .pin19: GPIO(sunXi:SunXiGPIO(letter:.C, pin:2)),
        .pin20: GPIO(sunXi:SunXiGPIO(letter:.C, pin:3)),
        .pin21: GPIO(sunXi:SunXiGPIO(letter:.C, pin:4)),
        .pin22: GPIO(sunXi:SunXiGPIO(letter:.C, pin:7)),
        .pin23: GPIO(sunXi:SunXiGPIO(letter:.D, pin:14)),
        .pin24: GPIO(sunXi:SunXiGPIO(letter:.G, pin:6)),
        .pin25: GPIO(sunXi:SunXiGPIO(letter:.G, pin:7)),
        .pin26: GPIO(sunXi:SunXiGPIO(letter:.G, pin:8)),
        .pin27: GPIO(sunXi:SunXiGPIO(letter:.G, pin:9))
    ]

    // OrangePiZero
    static let GPIOORANGEPIZERO: [GPIOName:GPIO] = [
        .pin2: GPIO(sunXi:SunXiGPIO(letter:.A, pin:12)),
        .pin3: GPIO(sunXi:SunXiGPIO(letter:.A, pin:11)),
        .pin4: GPIO(sunXi:SunXiGPIO(letter:.A, pin:6)),
        .pin7: GPIO(sunXi:SunXiGPIO(letter:.A, pin:10)),
        .pin8: GPIO(sunXi:SunXiGPIO(letter:.A, pin:13)),
        .pin9: GPIO(sunXi:SunXiGPIO(letter:.A, pin:16)),
        .pin10: GPIO(sunXi:SunXiGPIO(letter:.A, pin:15)),
        .pin11: GPIO(sunXi:SunXiGPIO(letter:.A, pin:14)),
        .pin14: GPIO(sunXi:SunXiGPIO(letter:.G, pin:6)),
        .pin15: GPIO(sunXi:SunXiGPIO(letter:.G, pin:7)),
        .pin17: GPIO(sunXi:SunXiGPIO(letter:.A, pin:1)),
        .pin18: GPIO(sunXi:SunXiGPIO(letter:.A, pin:7)),
        .pin22: GPIO(sunXi:SunXiGPIO(letter:.A, pin:3)),
        .pin23: GPIO(sunXi:SunXiGPIO(letter:.A, pin:19)),
        .pin24: GPIO(sunXi:SunXiGPIO(letter:.A, pin:18)),
        .pin25: GPIO(sunXi:SunXiGPIO(letter:.A, pin:2)),
        .pin27: GPIO(sunXi:SunXiGPIO(letter:.A, pin:0))
    ]
}
