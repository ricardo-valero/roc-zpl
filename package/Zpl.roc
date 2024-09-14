module []

enum = \flag ->
    when flag is
        FormatStart -> "^XA"
        FormatEnd -> "^XZ"
        FieldOrigin -> "^FO"
        FieldSeparator -> "^FS"
        FieldReverse -> "^FR"
        FieldData data -> "^FD" |> Str.concat data
        Font (height, width) -> "^A0N,$(Num.toStr height),$(Num.toStr width)"
        Color t ->
            when t is
                Black -> "B"
                White -> "W"

        Rotation t ->
            when t is
                R0 -> "N" # normal
                R90 -> "R" # rotate 90 degrees clockwise
                R180 -> "I" # inverted 180 degrees
                R270 -> "B" # bottom-up, 270 degrees

font = \{ name, rotation, height, width } ->
    Str.concat
        "^A$(name)"
        (
            [enum (Rotation rotation), Num.toStr height, Num.toStr width]
            |> Str.joinWith ""
        )

barcode = \data, type, { dpi ? D150, fw ? R0 } ->
    Str.concat
        "^B"
        (
            when type is
                # (read s Fw)
                Aztec { rotation ? fw, scale ? spec (MaxDpi dpi), eci ? "N", size ? 0, readerInit ? "N", symbols ? 1, id ? 0 } ->
                    Str.concat "0" ([enum (Rotation rotation), Num.toStr scale, eci, Num.toStr size, readerInit, Num.toStr symbols, Num.toStr id] |> Str.joinWith ",")
                    |> Str.concat (enum (FieldData data))

                Code11 { rotation ? fw, checkDigit, height, line, lineAbove } ->
                    Str.concat "1" ([enum (Rotation rotation), checkDigit, Num.toStr height, line, lineAbove] |> Str.joinWith ",")
                    |> Str.concat (enum (FieldData data))

                Interleaved2Of5 { rotation ? fw, height, line, lineAbove, checkDigit } ->
                    Str.concat "2" ([enum (Rotation rotation), Num.toStr height, line, lineAbove, checkDigit] |> Str.joinWith ",")
                    |> Str.concat (enum (FieldData data))

                Code39 { rotation ? fw, checkDigit, height, line, lineAbove } ->
                    Str.concat "3" ([enum (Rotation rotation), checkDigit, Num.toStr height, line, lineAbove] |> Str.joinWith ",")
                    |> Str.concat (enum (FieldData data))

                # model 2 only, rotation has no effect
                QrCode { model ? 2, scale, errorCorrection ? Standard, dataInput ? Automatic } ->
                    ec =
                        when errorCorrection is
                            UltraHighReliability -> "H"
                            HighReliability -> "Q"
                            Standard -> "M"
                            HighDensity -> "L"
                    di =
                        (
                            when dataInput is
                                Automatic -> ["A", ""]
                                Manual m ->
                                    [
                                        "M",
                                        when m is
                                            Numeric -> "N"
                                            Alphanumeric -> "A",
                                    ]
                        )
                        |> Str.joinWith ","

                    Str.concat "Q" (["", Num.toStr model, Num.toStr scale] |> Str.joinWith ",")
                    |> Str.concat (enum (FieldData ([ec, di, data] |> Str.joinWith "")))
        )

expect
    actual = barcode " 7. This is testing label 7" (Aztec { rotation: R90, scale: 7 }) {}
    expected = "^B0R,7,N,0,N,1,0^FD 7. This is testing label 7"
    actual == expected

expect
    actual = barcode "123456" (Code11 { checkDigit: "N", height: 150, line: "Y", lineAbove: "N" }) {}
    expected = "^B1N,N,150,Y,N^FD123456"
    actual == expected

expect
    actual = barcode "123456" (Interleaved2Of5 { checkDigit: "N", height: 150, line: "Y", lineAbove: "N" }) {}
    expected = "^B2N,150,Y,N,N^FD123456"
    actual == expected

expect
    actual = barcode "123456" (Code39 { checkDigit: "N", height: 150, line: "Y", lineAbove: "N" }) {}
    expected = "^B3N,N,150,Y,N^FD123456"
    actual == expected

expect
    actual = barcode "AC-42" (QrCode { scale: 10, dataInput: Manual Alphanumeric }) {}
    expected = "^BQ,2,10^FDMM,AAC-42"
    actual == expected

spec = \s ->
    when s is
        MaxDpi p ->
            when p is
                D150 -> 1
                D200 -> 2
                D300 -> 3
                D600 -> 6

write = \s, prop ->
    when prop is
        Fw value -> s |> &fw value

read = \s, prop ->
    when prop is
        Fw -> s |> .fw
        Dpi -> s |> .dpi

graphic = \type ->
    Str.concat
        "^G"
        (
            when type is
                Box { width ? 1, height ? 1, thickness ? 1, color ? Black, rounding ? 0 } ->
                    # TODO: how to use thickness default for width and height?
                    Str.concat "B" ([Num.toStr width, Num.toStr height, Num.toStr thickness, enum (Color color), Num.toStr rounding] |> Str.joinWith ",")

                Circle { width, thickness, color ? Black } ->
                    # TODO: clamp numbers like width 3 to 4095 as spec
                    Str.concat "C" ([Num.toStr width, Num.toStr thickness, enum (Color color)] |> Str.joinWith ",")

                Ellipse { width, height, thickness, color ? Black } ->
                    Str.concat "E" ([Num.toStr width, Num.toStr height, Num.toStr thickness, enum (Color color)] |> Str.joinWith ",")

                DiagonalLine { width, height, thickness, color ? Black, leaning ? Right } ->
                    l =
                        when leaning is
                            Right -> "R"
                            Left -> "L"
                    Str.concat "D" ([Num.toStr width, Num.toStr height, Num.toStr thickness, enum (Color color), l] |> Str.joinWith ",")

                Field { format ? Ascii, dataBytes, totalBytes, rowBytes, data } ->
                    f =
                        when format is
                            Ascii -> "A"
                            Binary -> "B"
                            Compressed -> "C"
                    Str.concat "F" ([f, Num.toStr dataBytes, Num.toStr totalBytes, Num.toStr rowBytes, data] |> Str.joinWith (","))

                Symbol { rotation ? R0, char } ->
                    d =
                        when char is
                            RegisteredTradeMark -> "A"
                            Copyright -> "B"
                            TradeMark -> "C"
                            UnderwritersLaboratoriesApproval -> "D"
                            CanadianStandardsAssociationApproval -> "E"

                    # TODO: How to get the last CF value for Num.toStr height, Num.toStr width
                    Str.concat "S" ([enum (Rotation rotation)] |> Str.joinWith (","))
                    |> Str.concat (enum (FieldData d))
        )

expect
    actual = graphic (Box { width: 200, height: 100, thickness: 8, rounding: 0 })
    expected = "^GB200,100,8,B,0"
    actual == expected
expect
    actual = graphic (Circle { width: 100, thickness: 4 })
    expected = "^GC100,4,B"
    actual == expected
expect
    actual = graphic (DiagonalLine { width: 150, height: 50, thickness: 2, leaning: Right })
    expected = "^GD150,50,2,B,R"
    actual == expected
expect
    actual = graphic (Ellipse { width: 120, height: 60, thickness: 3 })
    expected = "^GE120,60,3,B"
    actual == expected

expect
    image = ",:::::::::::L0GFGEJ0G1GFGE,L0IFG8H0G3GFGEHFGE,:L0HFG8G1G0G3GDIFG0G3G8,:L0IFG8H3G1HFGCG0GC,:L0IFGEG3GFG1HFG0G3I0G3GFGE,:L0G3IFG0GFG1HFG0GCG0G7G8HFGE,:L0G3IFGCG3G1GFGEG0GCG3G8G1HFGE,:M0JFG0GDGFGEG3G0GCG1IFGC,M0G3IFG0GFG9HFG3G0G7IFGC,:M0G1IFGCGDHFG0G3GDJF,:M0G1IFGCG2J0G3IF,:M0G1G8G7GFH0G7GFG0G3IF,:P0GCG0G3HFH0G3GE,:M0G2G0G7N0G6,:M0G3GFGEG3M0G6,M0HFGEG3G0G1GEG1H0GFGE,:M0GFGEG6GCG0G3HFGCG0GEG7G8,:M0GCG7G8GCG0G3G8G0GCG0GCG1GF,:M0G1GFG9GCG0G2G1G8GCG0GFG9GE,:N0G7G9GCH0G1GEGCG0G3G9G8,:L0G3HFG9GCG0G1G8G1H0G3GE,L0G3HFG9GFH0G7GEH0G1GE,:L0G3HFG8GFM0G6,:L0G3GEG7GEG3JFI0G1G8,:L0G3G2G1GFG0IFG9GFG0IFGC,:M0GEG0G7KFG0KFGC,:M0GFG8G1JFG8G3LF,:M0HFG8G3GFGEG7G8MFGC,L0G3HFGEH0G1GEG6MFGC,:L0G3G1IFH0G6G1MF,:L0G3G0G1JFG8G0LFGC,:L0GFGEH0IFG8G0G3KFGC,:L0HFGEM0KFGC,:L0MFG8H0KFGC,:K0G3G0G3KFG8H0LF,K0G3H0G1JFGEH0KFGC,:K0G3L0G3GEH0G3IFGC,:K0G3K0HFGEI0GFGE,:K0GCI0G7IFG9G8,:K0MFG1GFGE,:K0KFH0G3HF,:K0GCK0G3IFGC,K0GCJ0G3HFG8G7GFGC,:K0GCI0G1HFGCG1JFG8,:K0GCH0G7HFGCG0G7GFG0KFG3GFG9HFGC,:K0KFH0G3GFGEG3HFGEG7GCG3GEG1JFGE,:K0IFGEI0HFG8HFG3GEG1GCG3GCG7GEGFGCG1HF,:K0GCK0G3GFGEG0GFGCG3GEG1GCG3GCG7HFGCG3HFGC,K0GFJ0G3HFG8G1GFG0G3GEG1GCG3GDGFG9GFG0HFGEG0GC,:K0G3J0HFGCG0G7GCG0G3GEG1GCH3GEG7GFG3GEI0G3,:K0G3I0G7HFG0G7GFH0G3GEG1GFG0G3GEG7GCGFH0G7HFGC,:K0G3H0G1HFG0G1GFGEH0G1GEG1GFG0GFG9GFHCG1JFGE,:M0G1HFH0GFGEI0G1GFG9GFG0GEG1GFH0GFGEI0GE,:L0GCHFG8G0G3GEG6I0G1GFG8HFGEG7GFG0GFK0G1G8,:L0G3GEH0G3GFGDJFG0G7G8HFGCG7GEH0G3JFGDGE,L0G3I0HFG1LFG8HFGDGFG8G0MFGES0GC,:M0GCG0G1GFG0G3GFG8G0IFG8HFG3GEG6HFGEH0JFG8R0GC,:M0GEG0G7GCG0G2J0G3GFG8HFG3IFL0HFG8Q0G3GC,:M0G2G1GFM0G2G7G8GFGCIFM0G3GFG8L0LFGC,:M0G1GFGEH0HFGEH0G2G7G8GFGCHFG8G0G3IFGCG0G1GFGEK0MFGC,:M0G1GFGEH0JFG3GDGFG8GFGCGFG8G1MFG1GEG6J0G1MF,:N0G7GEH0JFGCGDGFG9GFG3GFG9PFGEJ0G1LFGC,N0G7GFGCJ0HFG1GFG9GFG3HFGEJ0G1JFGEJ0G7KFGC,:N0G7HFG3GFG8G0G3GCG3GEG1GFG3GFG8M0HFGEK0G7KFGC,:N0G1LFG0GCG3GEG1GCG3GFG8N0GEG6G1J0G7KF,:L0G3GEG7IFG0G1GFG3G0GFG8G7GCG3GFG8G1KFH0GCG6G7J0G1JFG8,:L0GCG1GEG0HFGCG0G7GCG0GFG8G7GCG3PFG0G1GFJ0G1G3,:M0G1GEG0GFG0GEG0G1GFG3GEG0G7GCG3IFGCG0G1IFGCG0G1GEGCJ0GF,:M0G1GEG0GFG0G3G8G7G0GFGEG1GFG0G3GEG6K0G1GFH0G1G8GCJ0GFGC,M0G1GEG0GFG0G3GEG6I0G7HFG3GEG6K0G1I0G1G8GFJ0HC,:J0G6H0JFGCG3GFG8K0JFG8G3IFGEJ0G7GFJ0HC,:J0G6G0GCI0IFGEM0IFGEJFGEJ0G7G0GCI0GFGC,:I0G1G9GFJ0G3HFGEM0G3KFGCG0G1J0G1HCI0GFGC,:I0G6G1L0HFGEN0JFGCG0G1GFGCI0G1HFH0G1,:H0G1G8G6L0HFGEN0G3IFG0G1GFG8G3GCI0HFGEG1HF,I0G1GEL0HFG8O0G7IFG3GEG0HFI0G3GCG3GEG1GC,:H0G2N0HFG8O0G1HFGCGFG8G1GFG0GEI0G3IF,:H0G2N0G3GFG8O0G7HFGCG1GEG7GCG0G2,:H0G1GEM0G3GFGEO0G7HFH0G1GFH0G1G8,:I0G1GFGCK0G3GFGEN0G1HFGCI0G1GCG0G3G8,:I0G1G8G3GFJ0G3GFGEN0G3HFK0G3G0G2,:J0G6G3GFJ0G3GFGEN0HFGEK0G3G0GC,J0G6HFJ0G3GFGEM0G3HFG8K0G3G0GC,:J0G7HFK0GFGEM0G3GFGEL0GCG0GC,:J0G1HFK0G3GEM0GFGEM0GCG3,:J0G1GFGCK0G3GEL0G3GFGEM0GCG3,:J0G1GFL0G3GFG8K0HFGEM0GCG3,:K0GCL0G3GFG8J0G1HFGCM0HC,:R0G1GFG8J0G7HFN0HC,R0G1GFG8I0G7GFGCN0G1G3GC,:R0G3GFG8H0G3HFGCN0G1G0GC,:R0HFG8H0IFGCN0G6G0GC,:R0HFG8G0G3IFGCM0G1G8G0GC,:Q0G3GFG8I0HFGEN0G7G8GF,:P0G3GFGET0G1GEG1,:P0HFGET0GFGEG1,O0G7IFG8R0G3IF,:O0G7HFGES0JFGC,:O0G1HFT0G3HFGE,:,::::"
    actual = graphic (Field { dataBytes: 5000, totalBytes: 5000, rowBytes: 25, data: image })
    expected = "^GFA,5000,5000,25,$(image)"
    actual == expected
expect
    actual = graphic (Symbol { char: TradeMark })
    expected = "^GSN^FDC"
    actual == expected

create = \elem ->
    when elem is
        Graphic x -> graphic x
        Barcode (x, y) -> barcode x y {}
        Text opt ->
            { fontSize, content } = opt
            "$(enum (Font fontSize))$(enum (FieldData content))"

field = \((top, left), children) ->
    "$(enum FieldOrigin)$(Num.toStr top),$(Num.toStr left)$(create children)$(enum FieldSeparator)"

build = \list ->
    list
    |> List.map field
    |> List.prepend (enum FormatStart)
    |> List.append (enum FormatEnd)
    |> Str.joinWith ""

expect
    actual = build [
        ((50, 50), Graphic (Box { width: 100, height: 50, thickness: 2 })),
        ((100, 100), Text { fontSize: (30, 30), content: "Hello zpl from roc!" }),
        ((150, 50), Barcode ("https://www.roc-lang.org/", QrCode { scale: 10 })),
        ((250, 50), Graphic (Field { dataBytes: 8000, totalBytes: 8000, rowBytes: 80, data: "data:image/png;base64" })),
    ]
    expected = "^XA^FO50,50^GB100,50,2,B,0^FS^FO100,100^A0N,30,30^FDHello zpl from roc!^FS^FO150,50^BQ,2,10^FDMA,https://www.roc-lang.org/^FS^FO250,50^GFA,8000,8000,80,data:image/png;base64^FS^XZ"
    actual == expected
