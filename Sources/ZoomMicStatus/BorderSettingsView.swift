import AppKit
import ZoomMicStatusCore

/// Thickness, opacity and fade controls, embedded in the menu so the border
/// updates live while dragging.
@MainActor
final class BorderSettingsView: NSView {
    private let strings: Strings
    private let onChange: (BorderStyle) -> Void
    private let widthSlider: NSSlider
    private let opacitySlider: NSSlider
    private let widthValue = NSTextField(labelWithString: "")
    private let opacityValue = NSTextField(labelWithString: "")
    private let fadeCheckbox: NSButton

    init(strings: Strings, style: BorderStyle, onChange: @escaping (BorderStyle) -> Void) {
        self.strings = strings
        self.onChange = onChange
        widthSlider = NSSlider(
            value: style.width,
            minValue: BorderStyle.widthRange.lowerBound,
            maxValue: BorderStyle.widthRange.upperBound,
            target: nil, action: nil
        )
        opacitySlider = NSSlider(
            value: style.opacity,
            minValue: BorderStyle.opacityRange.lowerBound,
            maxValue: BorderStyle.opacityRange.upperBound,
            target: nil, action: nil
        )
        fadeCheckbox = NSButton(checkboxWithTitle: strings.borderFade, target: nil, action: nil)
        fadeCheckbox.state = style.fades ? .on : .off
        super.init(frame: .zero)

        for control in [widthSlider, opacitySlider, fadeCheckbox] as [NSControl] {
            control.target = self
            control.action = #selector(controlChanged)
        }
        widthSlider.isContinuous = true
        opacitySlider.isContinuous = true
        fadeCheckbox.font = Typography.menuControl

        let grid = NSGridView(views: [
            [label(strings.borderWidth), widthSlider, widthValue],
            [label(strings.borderOpacity), opacitySlider, opacityValue],
            [NSGridCell.emptyContentView, fadeCheckbox, NSGridCell.emptyContentView],
        ])
        grid.rowSpacing = Spacing.menuControlRowSpacing
        grid.columnSpacing = Spacing.menuControlColumnSpacing
        grid.column(at: 1).width = Spacing.menuSliderWidth
        grid.column(at: 2).xPlacement = .trailing
        grid.translatesAutoresizingMaskIntoConstraints = false
        for value in [widthValue, opacityValue] {
            value.font = Typography.menuControlValue
            value.textColor = .secondaryLabelColor
        }

        addSubview(grid)
        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.menuControlInset),
            grid.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.menuControlInset),
            grid.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.menuControlRowSpacing),
            grid.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.menuControlRowSpacing),
        ])
        setFrameSize(fittingSize)
        updateValueLabels()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private var style: BorderStyle {
        BorderStyle(
            width: widthSlider.doubleValue.rounded(),
            opacity: opacitySlider.doubleValue,
            fades: fadeCheckbox.state == .on
        )
    }

    @objc private func controlChanged() {
        updateValueLabels()
        onChange(style)
    }

    private func updateValueLabels() {
        widthValue.stringValue = strings.points(style.width)
        opacityValue.stringValue = strings.percent(style.opacity)
    }

    private func label(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = Typography.menuControl
        return field
    }
}
