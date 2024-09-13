module []

enum = \flag ->
    when flag is
        Start -> "^XA"
        End -> "^XZ"
        Separator -> "^FS"
        FieldOrigin -> "^FO"
        GraphicBox -> "^GB"
        Font -> "^A0N"
        Text -> "^FD"
        QrCode -> "^BQ"
        Picture -> "^GF"

create = \elem ->
    when elem is
        Font size -> "$(enum Font),$(Num.toStr size.0),$(Num.toStr size.1)"
        Position (top, left) -> "$(enum FieldOrigin)$(Num.toStr top),$(Num.toStr left)"
        GraphicBox (position, opt) ->
            { width, height, borderWidth } = opt
            """
            $(create (Position position))
            $(enum GraphicBox)$(Num.toStr width),$(Num.toStr height),$(Num.toStr borderWidth),B,0$(enum Separator)
            """

        Text (position, opt) ->
            { fontSize, content } = opt
            """
            $(create (Position position))
            $(create (Font fontSize))
            $(enum Text)$(content)$(enum Separator)
            """

        QrCode (position, opt) ->
            { scale, content } = opt
            """
            $(create (Position position))
            $(enum QrCode),2,$(Num.toStr scale)
            $(enum Text)MA,$(content)$(enum Separator)
            """

        Picture (position, opt) ->
            { b, c, d, base64 } = opt
            """
            $(create (Position position))
            $(enum Picture)A,$(Num.toStr b),$(Num.toStr c),$(Num.toStr d),$(base64)$(enum Separator)
            """

build = \list ->
    list
    |> List.map create
    |> List.prepend (enum Start)
    |> List.append (enum End)
    |> Str.joinWith ""

expect
    actual = build [
        GraphicBox ((50, 50), { width: 100, height: 50, borderWidth: 2 }),
        Text ((100, 100), { fontSize: (30, 30), content: "hello zpl" }),
        QrCode ((50, 50), { scale: 10, content: "http://test.com" }),
        Picture ((50, 50), { b: 8000, c: 8000, d: 80, base64: "data:image/png;base64" }),
    ]
    expected =
        """
        ^XA
        ^FO50,50^GB100,50,2,B,0^FS
        ^FO100,100
        ^A0N,30,30
        ^FDhello zpl^FS
        ^FO50,50
        ^BQ,2,10
        ^FDMA,http://test.com^FS
        ^FO50,50
        ^GFA,8000,80,data:image/png;base64^FS
        ^XZ
        """
    actual == expected
