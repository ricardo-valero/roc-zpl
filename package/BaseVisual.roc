module [BaseVisual]

import Property exposing [GridPosition, Size, Spacing]

BaseVisual : {
    invert : Bool,
    fixed : Bool,
    grid : GridPosition,
    width : Size,
    height : Size,
    top : Size,
    left : Size,
    margin : Spacing,
}

# default = {
# this.invert = false;
# this.fixed = false;
# this.grid = new GridPosition();
# this.width = new Size();
# this.height = new Size();
# this.top = new Size();
# this.left = new Size();
# this.margin = new Spacing();
# }
#

getSize = \prop -> Property.getSizeValue prop

getPosition = \component -> \offsetLeft, offsetTop, availableWidth, availableHeight ->
        # gets start position and size of content
        left = getSize component.left + component.margin.left
        top = getSize component.top + component.margin.top

        width = getSize component.width || (availableWidth - Property.getSpacingHorizontal component.margin)
        height = getSize component.height || (availableHeight - Property.getSpacingVertical component.margin)

        # if (typeof(component.top) == 'object' && component.top.sizeType == SizeType.Fraction) {
        #  top = (availableHeight * component.top.value);
        # }
        # if (typeof(component.left) == 'object' && component.left.sizeType == SizeType.Fraction) {
        #  left = (availableWidth * component.left.value);
        # }

        {
            left: Num.round (left + offsetLeft),
            top: Num.round (top + offsetTop),
            width: Num.round (width),
            height: Num.round (height),
        }

#  calculateUnits() {
#    const units = {
#      absolute: {
#        width: 0,
#        height: 0
#      },
#      relative: {
#        width: 0,
#        height: 0
#      }
#    }

#    const elements = component.content || [];

#    for (let element of elements) {
#      if (!element.margin || !element.border || !element.width || !element.height) continue;

#      units.absolute.width += element.margin.horizontal + (this.border || 0);
#      units.absolute.height += element.margin.vertical + (this.border || 0);

#      if (typeof(element.border) == 'number') {
#        units.absolute.width += element.border * 2;
#        units.absolute.height += element.border * 2;
#      }

#      if (typeof(element.width) == 'number') {
#        units.absolute.width += element.width;
#      } else if (element.width.sizeType == SizeType.Absolute) {
#        units.absolute.width += element.width.value;
#      } else {
#        units.relative.width += element.width.value;
#      }

#      if (typeof(element.height) == 'number') {
#        units.absolute.height += element.height;
#      } else if (element.height.sizeType == SizeType.Absolute) {
#        units.absolute.height += element.height.value;
#      } else {
#        units.relative.height += element.height.value;
#      }
#    }

#    return units;
#  }
# }
