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
        .P0: RaspberryGPIO(name:"GPIO0", id:0, baseAddr:0x20000000),
        .P1: RaspberryGPIO(name:"GPIO1", id:1, baseAddr:0x20000000),
        .P4: RaspberryGPIO(name:"GPIO4", id:4, baseAddr:0x20000000),
        .P7: RaspberryGPIO(name:"GPIO7", id:7, baseAddr:0x20000000),
        .P8: RaspberryGPIO(name:"GPIO8", id:8, baseAddr:0x20000000),
        .P9: RaspberryGPIO(name:"GPIO9", id:9, baseAddr:0x20000000),
        .P10: RaspberryGPIO(name:"GPIO10", id:10, baseAddr:0x20000000),
        .P11: RaspberryGPIO(name:"GPIO11", id:11, baseAddr:0x20000000),
        .P14: RaspberryGPIO(name:"GPIO14", id:14, baseAddr:0x20000000),
        .P15: RaspberryGPIO(name:"GPIO15", id:15, baseAddr:0x20000000),
        .P17: RaspberryGPIO(name:"GPIO17", id:17, baseAddr:0x20000000),
        .P18: RaspberryGPIO(name:"GPIO18", id:18, baseAddr:0x20000000),
        .P21: RaspberryGPIO(name:"GPIO21", id:21, baseAddr:0x20000000),
        .P22: RaspberryGPIO(name:"GPIO22", id:22, baseAddr:0x20000000),
        .P23: RaspberryGPIO(name:"GPIO23", id:23, baseAddr:0x20000000),
        .P24: RaspberryGPIO(name:"GPIO24", id:24, baseAddr:0x20000000),
        .P25: RaspberryGPIO(name:"GPIO25", id:25, baseAddr:0x20000000)
    ]

    // RaspberryPi A and B Revision 2 (After September 2012) - 26 pin header boards
    //TODO: Additional GPIO from 28-31 ignored for now
    // 2, 3, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 22, 23, 24, 25, 27
    static let GPIORPIRev2: [GPIOName:GPIO] = [
        .P2: RaspberryGPIO(name:"GPIO2", id:2, baseAddr:0x20000000),
        .P3: RaspberryGPIO(name:"GPIO3", id:3, baseAddr:0x20000000),
        .P4: RaspberryGPIO(name:"GPIO4", id:4, baseAddr:0x20000000),
        .P7: RaspberryGPIO(name:"GPIO7", id:7, baseAddr:0x20000000),
        .P8: RaspberryGPIO(name:"GPIO8", id:8, baseAddr:0x20000000),
        .P9: RaspberryGPIO(name:"GPIO9", id:9, baseAddr:0x20000000),
        .P10: RaspberryGPIO(name:"GPIO10", id:10, baseAddr:0x20000000),
        .P11: RaspberryGPIO(name:"GPIO11", id:11, baseAddr:0x20000000),
        .P14: RaspberryGPIO(name:"GPIO14", id:14, baseAddr:0x20000000),
        .P15: RaspberryGPIO(name:"GPIO15", id:15, baseAddr:0x20000000),
        .P17: RaspberryGPIO(name:"GPIO17", id:17, baseAddr:0x20000000),
        .P18: RaspberryGPIO(name:"GPIO18", id:18, baseAddr:0x20000000),
        .P22: RaspberryGPIO(name:"GPIO22", id:22, baseAddr:0x20000000),
        .P23: RaspberryGPIO(name:"GPIO23", id:23, baseAddr:0x20000000),
        .P24: RaspberryGPIO(name:"GPIO24", id:24, baseAddr:0x20000000),
        .P25: RaspberryGPIO(name:"GPIO25", id:25, baseAddr:0x20000000),
        .P27: RaspberryGPIO(name:"GPIO27", id:27, baseAddr:0x20000000)
    ]

    // RaspberryPi A+ and B+, Raspberry Zero - 40 pin header boards
    // 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
    static let GPIORPIPlusZERO: [GPIOName:GPIO] = [
        .P2: RaspberryGPIO(name:"GPIO2", id:2, baseAddr:0x20000000),
        .P3: RaspberryGPIO(name:"GPIO3", id:3, baseAddr:0x20000000),
        .P4: RaspberryGPIO(name:"GPIO4", id:4, baseAddr:0x20000000),
        .P5: RaspberryGPIO(name:"GPIO5", id:5, baseAddr:0x20000000),
        .P6: RaspberryGPIO(name:"GPIO6", id:6, baseAddr:0x20000000),
        .P7: RaspberryGPIO(name:"GPIO7", id:7, baseAddr:0x20000000),
        .P8: RaspberryGPIO(name:"GPIO8", id:8, baseAddr:0x20000000),
        .P9: RaspberryGPIO(name:"GPIO9", id:9, baseAddr:0x20000000),
        .P10: RaspberryGPIO(name:"GPIO10", id:10, baseAddr:0x20000000),
        .P11: RaspberryGPIO(name:"GPIO11", id:11, baseAddr:0x20000000),
        .P12: RaspberryGPIO(name:"GPIO12", id:12, baseAddr:0x20000000),
        .P13: RaspberryGPIO(name:"GPIO13", id:13, baseAddr:0x20000000),
        .P14: RaspberryGPIO(name:"GPIO14", id:14, baseAddr:0x20000000),
        .P15: RaspberryGPIO(name:"GPIO15", id:15, baseAddr:0x20000000),
        .P16: RaspberryGPIO(name:"GPIO16", id:16, baseAddr:0x20000000),
        .P17: RaspberryGPIO(name:"GPIO17", id:17, baseAddr:0x20000000),
        .P18: RaspberryGPIO(name:"GPIO18", id:18, baseAddr:0x20000000),
        .P19: RaspberryGPIO(name:"GPIO19", id:19, baseAddr:0x20000000),
        .P20: RaspberryGPIO(name:"GPIO20", id:20, baseAddr:0x20000000),
        .P21: RaspberryGPIO(name:"GPIO21", id:21, baseAddr:0x20000000),
        .P22: RaspberryGPIO(name:"GPIO22", id:22, baseAddr:0x20000000),
        .P23: RaspberryGPIO(name:"GPIO23", id:23, baseAddr:0x20000000),
        .P24: RaspberryGPIO(name:"GPIO24", id:24, baseAddr:0x20000000),
        .P25: RaspberryGPIO(name:"GPIO25", id:25, baseAddr:0x20000000),
        .P26: RaspberryGPIO(name:"GPIO26", id:26, baseAddr:0x20000000),
        .P27: RaspberryGPIO(name:"GPIO27", id:27, baseAddr:0x20000000)
    ]

    // RaspberryPi 2
    // 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
    static let GPIORPI2: [GPIOName:GPIO] = [
        .P2: RaspberryGPIO(name:"GPIO2", id:2, baseAddr:0x3F000000),
        .P3: RaspberryGPIO(name:"GPIO3", id:3, baseAddr:0x3F000000),
        .P4: RaspberryGPIO(name:"GPIO4", id:4, baseAddr:0x3F000000),
        .P5: RaspberryGPIO(name:"GPIO5", id:5, baseAddr:0x3F000000),
        .P6: RaspberryGPIO(name:"GPIO6", id:6, baseAddr:0x3F000000),
        .P7: RaspberryGPIO(name:"GPIO7", id:7, baseAddr:0x3F000000),
        .P8: RaspberryGPIO(name:"GPIO8", id:8, baseAddr:0x3F000000),
        .P9: RaspberryGPIO(name:"GPIO9", id:9, baseAddr:0x3F000000),
        .P10: RaspberryGPIO(name:"GPIO10", id:10, baseAddr:0x3F000000),
        .P11: RaspberryGPIO(name:"GPIO11", id:11, baseAddr:0x3F000000),
        .P12: RaspberryGPIO(name:"GPIO12", id:12, baseAddr:0x3F000000),
        .P13: RaspberryGPIO(name:"GPIO13", id:13, baseAddr:0x3F000000),
        .P14: RaspberryGPIO(name:"GPIO14", id:14, baseAddr:0x3F000000),
        .P15: RaspberryGPIO(name:"GPIO15", id:15, baseAddr:0x3F000000),
        .P16: RaspberryGPIO(name:"GPIO16", id:16, baseAddr:0x3F000000),
        .P17: RaspberryGPIO(name:"GPIO17", id:17, baseAddr:0x3F000000),
        .P18: RaspberryGPIO(name:"GPIO18", id:18, baseAddr:0x3F000000),
        .P19: RaspberryGPIO(name:"GPIO19", id:19, baseAddr:0x3F000000),
        .P20: RaspberryGPIO(name:"GPIO20", id:20, baseAddr:0x3F000000),
        .P21: RaspberryGPIO(name:"GPIO21", id:21, baseAddr:0x3F000000),
        .P22: RaspberryGPIO(name:"GPIO22", id:22, baseAddr:0x3F000000),
        .P23: RaspberryGPIO(name:"GPIO23", id:23, baseAddr:0x3F000000),
        .P24: RaspberryGPIO(name:"GPIO24", id:24, baseAddr:0x3F000000),
        .P25: RaspberryGPIO(name:"GPIO25", id:25, baseAddr:0x3F000000),
        .P26: RaspberryGPIO(name:"GPIO26", id:26, baseAddr:0x3F000000),
        .P27: RaspberryGPIO(name:"GPIO27", id:27, baseAddr:0x3F000000)
    ]
 
     // RaspberryPi 4
    // 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
    static let GPIORPI4: [GPIOName:GPIO] = [
        .P2: RaspberryGPIO(name:"GPIO2", id:2, baseAddr:0x7E000000),
        .P3: RaspberryGPIO(name:"GPIO3", id:3, baseAddr:0x7E000000),
        .P4: RaspberryGPIO(name:"GPIO4", id:4, baseAddr:0x7E000000),
        .P5: RaspberryGPIO(name:"GPIO5", id:5, baseAddr:0x7E000000),
        .P6: RaspberryGPIO(name:"GPIO6", id:6, baseAddr:0x7E000000),
        .P7: RaspberryGPIO(name:"GPIO7", id:7, baseAddr:0x7E000000),
        .P8: RaspberryGPIO(name:"GPIO8", id:8, baseAddr:0x7E000000),
        .P9: RaspberryGPIO(name:"GPIO9", id:9, baseAddr:0x7E000000),
        .P10: RaspberryGPIO(name:"GPIO10", id:10, baseAddr:0x7E000000),
        .P11: RaspberryGPIO(name:"GPIO11", id:11, baseAddr:0x7E000000),
        .P12: RaspberryGPIO(name:"GPIO12", id:12, baseAddr:0x7E000000),
        .P13: RaspberryGPIO(name:"GPIO13", id:13, baseAddr:0x7E000000),
        .P14: RaspberryGPIO(name:"GPIO14", id:14, baseAddr:0x7E000000),
        .P15: RaspberryGPIO(name:"GPIO15", id:15, baseAddr:0x7E000000),
        .P16: RaspberryGPIO(name:"GPIO16", id:16, baseAddr:0x7E000000),
        .P17: RaspberryGPIO(name:"GPIO17", id:17, baseAddr:0x7E000000),
        .P18: RaspberryGPIO(name:"GPIO18", id:18, baseAddr:0x7E000000),
        .P19: RaspberryGPIO(name:"GPIO19", id:19, baseAddr:0x7E000000),
        .P20: RaspberryGPIO(name:"GPIO20", id:20, baseAddr:0x7E000000),
        .P21: RaspberryGPIO(name:"GPIO21", id:21, baseAddr:0x7E000000),
        .P22: RaspberryGPIO(name:"GPIO22", id:22, baseAddr:0x7E000000),
        .P23: RaspberryGPIO(name:"GPIO23", id:23, baseAddr:0x7E000000),
        .P24: RaspberryGPIO(name:"GPIO24", id:24, baseAddr:0x7E000000),
        .P25: RaspberryGPIO(name:"GPIO25", id:25, baseAddr:0x7E000000),
        .P26: RaspberryGPIO(name:"GPIO26", id:26, baseAddr:0x7E000000),
        .P27: RaspberryGPIO(name:"GPIO27", id:27, baseAddr:0x7E000000)
    ]

    // C.H.I.P.
    // Pins XIO-P0 to P7 linearly map to:
    // kernel 4.3: gpio408 to gpio415
    // kernel 4.4.11: gpio1016 to gpio1023 
    // kernel 4.4.13-ntc-mlc: gpio1013 to gpio 1020 (latest, available since december 2016)
    //
    // See: https://docs.getchip.com/chip.html#kernel-4-3-vs-4-4-gpio-how-to-tell-the-difference
    static let GPIOCHIP: [GPIOName:GPIO] = [
        .P0: GPIO(name:"XIO-P0", id:1013),
        .P1: GPIO(name:"XIO-P1", id:1014),
        .P2: GPIO(name:"XIO-P2", id:1015),
        .P3: GPIO(name:"XIO-P3", id:1016),
        .P4: GPIO(name:"XIO-P4", id:1017),
        .P5: GPIO(name:"XIO-P5", id:1018),
        .P6: GPIO(name:"XIO-P6", id:1019),
        .P7: GPIO(name:"XIO-P7", id:1020),
        .P8: GPIO(name:"LCD_D2", id:98), //LCD pins (PDn pins on AllWinner doc) are calculated with 32*(PD=3) + id
        .P9: GPIO(name:"LCD_D3", id:99),
        .P10: GPIO(name:"LCD_D4", id:100),
        .P11: GPIO(name:"LCD_D5", id:101),
        .P12: GPIO(name:"LCD_D6", id:102),
        .P13: GPIO(name:"LCD_D7", id:103),
        .P14: GPIO(name:"LCD_D8", id:104),
        .P15: GPIO(name:"LCD_D9", id:105),
        .P16: GPIO(name:"LCD_D10", id:106),
        .P17: GPIO(name:"LCD_D11", id:107),
        .P18: GPIO(name:"LCD_D12", id:108),
        .P19: GPIO(name:"LCD_D13", id:109),
        .P20: GPIO(name:"LCD_D14", id:110),
        .P21: GPIO(name:"LCD_D15", id:111),
        .P22: GPIO(name:"LCD_D16", id:112),
        .P23: GPIO(name:"LCD_D17", id:113),
        .P24: GPIO(name:"LCD_D18", id:114),
        .P25: GPIO(name:"LCD_D19", id:115),
        .P26: GPIO(name:"LCD_D20", id:116),
        .P27: GPIO(name:"LCD_D21", id:117),
        .P28: GPIO(name:"LCD_D22", id:118),
        .P29: GPIO(name:"LCD_D23", id:119),
        .P30: GPIO(name:"LCD_D24", id:120),
        .P31: GPIO(name:"LCD_D25", id:121),
        .P32: GPIO(name:"LCD_D26", id:122),
        .P33: GPIO(name:"LCD_D27", id:123)
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
    //included here: https://github.com/CircuitCo/BeagleBone-Black/blob/master/BBB_SRM.pdf?raw=true
    //Clearly this does not support mode change.
    //
    static let GPIOBEAGLEBONE: [GPIOName:GPIO] = [
        .P0: GPIO(name:"P8_PIN03_GPIO1_6", id:38),  //P8
        .P1: GPIO(name:"P8_PIN04_GPIO1_7", id:39),
        .P2: GPIO(name:"P8_PIN05_GPIO1_2", id:34),
        .P3: GPIO(name:"P8_PIN06_GPIO1_3", id:35),
        .P4: GPIO(name:"P8_PIN11_GPIO1_13", id:45),
        .P5: GPIO(name:"P8_PIN12_GPIO1_12", id:44),
        .P6: GPIO(name:"P8_PIN14_GPIO0_26", id:26),
        .P7: GPIO(name:"P8_PIN15_GPIO1_15", id:47),
        .P8: GPIO(name:"P8_PIN16_GPIO1_14", id:46),
        .P9: GPIO(name:"P8_PIN17_GPIO0_27", id:27),
        .P10: GPIO(name:"P8_PIN18_GPIO2_1", id:65),
        .P11: GPIO(name:"P8_PIN20_GPIO1_31", id:63),
        .P12: GPIO(name:"P8_PIN21_GPIO1_30", id:62),
        .P13: GPIO(name:"P8_PIN22_GPIO1_5", id:37),
        .P14: GPIO(name:"P8_PIN23_GPIO1_4", id:36),
        .P15: GPIO(name:"P8_PIN24_GPIO1_1", id:33),
        .P16: GPIO(name:"P8_PIN25_GPIO1_0", id:32),
        .P17: GPIO(name:"P8_PIN26_GPIO1_29", id:61),
        .P18: GPIO(name:"P8_PIN27_GPIO2_22", id:86),
        .P19: GPIO(name:"P8_PIN28_GPIO2_24", id:88),
        .P20: GPIO(name:"P8_PIN29_GPIO2_23", id:87),
        .P21: GPIO(name:"P8_PIN30_GPIO2_25", id:89),
        .P22: GPIO(name:"P8_PIN39_GPIO2_12", id:76),
        .P23: GPIO(name:"P8_PIN40_GPIO2_13", id:77),
        .P24: GPIO(name:"P8_PIN41_GPIO2_10", id:74),
        .P25: GPIO(name:"P8_PIN42_GPIO2_11", id:75),
        .P26: GPIO(name:"P8_PIN43_GPIO2_8", id:72),
        .P27: GPIO(name:"P8_PIN44_GPIO2_9", id:73),
        .P28: GPIO(name:"P8_PIN45_GPIO2_6", id:70),
        .P29: GPIO(name:"P8_PIN46_GPIO2_7", id:71),
        .P30: GPIO(name:"P9_PIN12_GPIO1_28", id:60),   //P9
        .P31: GPIO(name:"P9_PIN15_GPIO1_16", id:48),
        .P32: GPIO(name:"P9_PIN23_GPIO1_17", id:49),   //Ignore Pin25, requires oscillator disabled
        .P33: GPIO(name:"P9_PIN27_GPIO3_19", id:125)
    ]

    // OrangePi
    // The pins are ordered by name: A0-A21(P0-P16), C0-C7(P17-P22), D14(P23), G6-G9(P24-P27)
    static let GPIOORANGEPI: [GPIOName:GPIO] = [
        .P0: GPIO(sunXi:SunXiGPIO(letter: .A, pin:0)),
        .P1: GPIO(sunXi:SunXiGPIO(letter:.A, pin:1)),
        .P2: GPIO(sunXi:SunXiGPIO(letter:.A, pin:2)),
        .P3: GPIO(sunXi:SunXiGPIO(letter:.A, pin:3)),
        .P4: GPIO(sunXi:SunXiGPIO(letter:.A, pin:6)),
        .P5: GPIO(sunXi:SunXiGPIO(letter:.A, pin:7)),
        .P6: GPIO(sunXi:SunXiGPIO(letter:.A, pin:8)),
        .P7: GPIO(sunXi:SunXiGPIO(letter:.A, pin:9)),
        .P8: GPIO(sunXi:SunXiGPIO(letter:.A, pin:10)),
        .P9: GPIO(sunXi:SunXiGPIO(letter:.A, pin:11)),
        .P10: GPIO(sunXi:SunXiGPIO(letter:.A, pin:12)),
        .P11: GPIO(sunXi:SunXiGPIO(letter:.A, pin:13)),
        .P12: GPIO(sunXi:SunXiGPIO(letter:.A, pin:14)),
        .P13: GPIO(sunXi:SunXiGPIO(letter:.A, pin:18)),
        .P14: GPIO(sunXi:SunXiGPIO(letter:.A, pin:19)),
        .P15: GPIO(sunXi:SunXiGPIO(letter:.A, pin:20)),
        .P16: GPIO(sunXi:SunXiGPIO(letter:.A, pin:21)),
        .P17: GPIO(sunXi:SunXiGPIO(letter:.C, pin:0)),
        .P18: GPIO(sunXi:SunXiGPIO(letter:.C, pin:1)),
        .P19: GPIO(sunXi:SunXiGPIO(letter:.C, pin:2)),
        .P20: GPIO(sunXi:SunXiGPIO(letter:.C, pin:3)),
        .P21: GPIO(sunXi:SunXiGPIO(letter:.C, pin:4)),
        .P22: GPIO(sunXi:SunXiGPIO(letter:.C, pin:7)),
        .P23: GPIO(sunXi:SunXiGPIO(letter:.D, pin:14)),
        .P24: GPIO(sunXi:SunXiGPIO(letter:.G, pin:6)),
        .P25: GPIO(sunXi:SunXiGPIO(letter:.G, pin:7)),
        .P26: GPIO(sunXi:SunXiGPIO(letter:.G, pin:8)),
        .P27: GPIO(sunXi:SunXiGPIO(letter:.G, pin:9))
    ]

    // OrangePiZero
    static let GPIOORANGEPIZERO: [GPIOName:GPIO] = [
        .P2: GPIO(sunXi:SunXiGPIO(letter:.A, pin:12)),
        .P3: GPIO(sunXi:SunXiGPIO(letter:.A, pin:11)),
        .P4: GPIO(sunXi:SunXiGPIO(letter:.A, pin:6)),
        .P7: GPIO(sunXi:SunXiGPIO(letter:.A, pin:10)),
        .P8: GPIO(sunXi:SunXiGPIO(letter:.A, pin:13)),
        .P9: GPIO(sunXi:SunXiGPIO(letter:.A, pin:16)),
        .P10: GPIO(sunXi:SunXiGPIO(letter:.A, pin:15)),
        .P11: GPIO(sunXi:SunXiGPIO(letter:.A, pin:14)),
        .P14: GPIO(sunXi:SunXiGPIO(letter:.G, pin:6)),
        .P15: GPIO(sunXi:SunXiGPIO(letter:.G, pin:7)),
        .P17: GPIO(sunXi:SunXiGPIO(letter:.A, pin:1)),
        .P18: GPIO(sunXi:SunXiGPIO(letter:.A, pin:7)),
        .P22: GPIO(sunXi:SunXiGPIO(letter:.A, pin:3)),
        .P23: GPIO(sunXi:SunXiGPIO(letter:.A, pin:19)),
        .P24: GPIO(sunXi:SunXiGPIO(letter:.A, pin:18)),
        .P25: GPIO(sunXi:SunXiGPIO(letter:.A, pin:2)),
        .P27: GPIO(sunXi:SunXiGPIO(letter:.A, pin:0))
    ]
}
