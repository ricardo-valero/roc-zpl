module [
    Alignment,
    BarcodeType,
    FontFamilyName,
    Rotation,
    GraphicData,
    GridPosition,
    Size,
    Spacing,
    getSizeValue,
    getSpacingHorizontal,
    getSpacingVertical,
]

Alignment : [Start, Center, End]

BarcodeType : [Code11, Interleaved25, Code39, PlanetCode, PDF417, EAN8, UPCE, Code93, Code128, EAN13, Industrial25, Standard25, ANSICodabar, Logmars, MSI, Plessey, QRCode, DataMatrix, PostNet]

FontFamilyName : [A, B, D, E, F, G, H, Zero, GS, P, Q, R, S, T, U, V]

# PrintDensity : [6dpmm,8dpmm,12dpmm,24dpmm]

Rotation : [Normal, Right, Bottom, Left]

fontFamily = \fontFamilyName -> fontFamilyDefinition fontFamilyName

fontFamilyDefinition = \x -> x

GraphicData x : {
    data : List x,
    width : U64,
    height : U64,
}

GridPosition : {
    column : U64,
    row : U64,
}

Size : {
    value : U64,
    type : SizeType,
}
SizeType : [
    Absolute, # exact size
    Fraction U64, # size as part of parent
    Relative U64, # size together with siblings as part of parent
]
getSizeValue : Size -> U64
getSizeValue = \size ->
    when size.type is
        Relative u -> size.value * u
        Fraction available -> size.value * available
        _ -> size.value

Spacing : { left : U64, top : U64, right : U64, bottom : U64 }

getSpacingHorizontal : Spacing -> U64
getSpacingHorizontal = \spacing -> Num.add spacing.left spacing.right

getSpacingVertical : Spacing -> U64
getSpacingVertical = \spacing -> Num.add spacing.top spacing.bottom

getSpacingHorizontalDifference : Spacing -> U64
getSpacingHorizontalDifference = \spacing -> Num.absDiff spacing.left spacing.right

getSpacingVerticalDifference : Spacing -> U64
getSpacingVerticalDifference = \spacing -> Num.absDiff spacing.top spacing.bottom
