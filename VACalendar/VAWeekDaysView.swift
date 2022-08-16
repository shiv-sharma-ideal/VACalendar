import UIKit

public enum VAWeekDaysSymbolsType {
    case short, veryShort
    
    func names(from calendar: Calendar) -> [String] {
        switch self {
        case .short:
            return calendar.shortWeekdaySymbols
        case .veryShort:
            return calendar.veryShortWeekdaySymbols
        }
    }
    
}

public struct VAWeekDaysViewAppearance {
    
    let symbolsType: VAWeekDaysSymbolsType
    let weekDayTextColor: UIColor
    let weekDayTextFont: UIFont
    let leftInset: CGFloat
    let rightInset: CGFloat
    let separatorBackgroundColor: UIColor
    let calendar: Calendar
    
    public init(
        symbolsType: VAWeekDaysSymbolsType = .veryShort,
        weekDayTextColor: UIColor = .black,
        weekDayTextFont: UIFont = UIFont.systemFont(ofSize: 15),
        leftInset: CGFloat = 0.0,
        rightInset: CGFloat = 0.0,
        separatorBackgroundColor: UIColor = .lightGray,
        calendar: Calendar = Calendar.current) {
        self.symbolsType = symbolsType
        self.weekDayTextColor = weekDayTextColor
        self.weekDayTextFont = weekDayTextFont
        self.leftInset = leftInset
        self.rightInset = rightInset
        self.separatorBackgroundColor = separatorBackgroundColor
        self.calendar = calendar
    }
    
}

public class VAWeekDaysView: UIView {
    
    public var appearance = VAWeekDaysViewAppearance() {
        didSet {
            setupView()
        }
    }
    
    private let separatorView = UIView()
    private var dayLabels = [UILabel]()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupView()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let separatorHeight = 1 / UIScreen.main.scale
        separatorView.frame = CGRect(
            x: 0,
            y: 0,
            width: frame.width,
            height: separatorHeight
        )

        let width = frame.width - (appearance.leftInset + appearance.rightInset)
        let dayWidth = width / CGFloat(dayLabels.count)

        dayLabels.enumerated().forEach { index, label in
            let x = index == 0 ? appearance.leftInset : dayLabels[index - 1].frame.maxX
            
            label.frame = CGRect(
                x: x,
                y: 1,
                width: dayWidth,
                height: self.frame.height
            )
        }
    }
    
    private func setupView() {
        subviews.forEach { $0.removeFromSuperview() }
        dayLabels = []
        
        let names = getWeekdayNames()
        names.enumerated().forEach { index, name in
            let label = UILabel()
            label.text = name
            label.textAlignment = .center
            label.font = appearance.weekDayTextFont
            label.textColor = appearance.weekDayTextColor
            dayLabels.append(label)
            addSubview(label)
        }
        
        separatorView.backgroundColor = appearance.separatorBackgroundColor
        addSubview(separatorView)
        layoutSubviews()
    }
    
    private func getWeekdayNames() -> [String] {
        let symbols = appearance.symbolsType.names(from: appearance.calendar)
        
        if appearance.calendar.firstWeekday == 1 {
            return symbols
        } else {
            let allDaysWihoutFirst = Array(symbols[appearance.calendar.firstWeekday - 1..<symbols.count])
            return allDaysWihoutFirst + symbols[0..<appearance.calendar.firstWeekday - 1]
        }
    }
    
}
