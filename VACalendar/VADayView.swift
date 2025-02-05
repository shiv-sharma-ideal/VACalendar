//
//  VADayView.swift
//  VACalendar
//
//  Created by Anton Vodolazkyi on 20.02.18.
//  Copyright © 2018 Vodolazkyi. All rights reserved.
//

import UIKit

@objc
public protocol VADayViewAppearanceDelegate: class {
    @objc optional func font(for state: VADayState) -> UIFont
    @objc optional func textColor(for state: VADayState) -> UIColor
    @objc optional func textBackgroundColor(for state: VADayState) -> UIColor
    @objc optional func backgroundColor(for state: VADayState) -> UIColor
    @objc optional func borderWidth(for state: VADayState) -> CGFloat
    @objc optional func borderColor(for state: VADayState) -> UIColor
    @objc optional func dotBottomVerticalOffset(for state: VADayState) -> CGFloat
    @objc optional func shape() -> VADayShape
    // percent of the selected area to be painted
    @objc optional func selectedArea() -> CGFloat
}

protocol VADayViewDelegate: class {
    func dayStateChanged(_ day: VADay)
}

class VADayView: UIView {

    var isToday: Bool = false
    var day: VADay {
        didSet { isToday = Calendar.current.isDateInToday(day.date) }
    }
    weak var delegate: VADayViewDelegate?
    
    weak var dayViewAppearanceDelegate: VADayViewAppearanceDelegate? {
        return (superview as? VAWeekView)?.dayViewAppearanceDelegate
    }
    
    private var dotStackView: UIStackView {
        let stack = UIStackView()
        stack.distribution = .fillEqually
        stack.axis = .horizontal
        stack.spacing = dotSpacing
        return stack
    }
    
    private let dotSpacing: CGFloat = 6
    private let dotSize: CGFloat = 6
    private var supplementaryViews = [UIView]()
    private let dateLabel = UILabel()
    
    init(day: VADay) {
        self.day = day
        super.init(frame: .zero)
        
        self.day.stateChanged = { [weak self] state in
            self?.setState(state)
        }
        
        self.day.supplementariesDidUpdate = { [weak self] in
            self?.updateSupplementaryViews()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSelect))
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupDay() {
        updateSupplementaryViews()
        let shortestSide: CGFloat = (frame.width < frame.height ? frame.width : frame.height)
        let side: CGFloat = shortestSide * (dayViewAppearanceDelegate?.selectedArea?() ?? 0.8)
        
        dateLabel.font = dayViewAppearanceDelegate?.font?(for: day.state) ?? dateLabel.font
        dateLabel.text = VAFormatters.dayFormatter.string(from: day.date)
        dateLabel.textAlignment = .center
        dateLabel.frame = CGRect(
            x: 0,
            y: 0,
            width: 30.0,
            height: 30.0
        )
        dateLabel.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
        setState(day.state)
        addSubview(dateLabel)
    }
    
    @objc
    private func didTapSelect() {
        guard day.state != .out && day.state != .unavailable else { return }
        delegate?.dayStateChanged(day)
    }
    
    private func setState(_ state: VADayState) {
        if dayViewAppearanceDelegate?.shape?() == .circle && state == .selected {
            dateLabel.clipsToBounds = true
            dateLabel.layer.cornerRadius = dateLabel.frame.height / 2
        }
        dateLabel.font = dayViewAppearanceDelegate?.font?(for: day.state) ?? dateLabel.font
        if Calendar.current.isDateInToday(day.date) && state == .available {
            dateLabel.font = dayViewAppearanceDelegate?.font?(for: .selected) ?? dateLabel.font
            dateLabel.textColor = dayViewAppearanceDelegate?.textColor?(for: .today)
        } else if Date().compare(day.date) == .orderedDescending && state == .available && state != .selected {
            dateLabel.textColor = dayViewAppearanceDelegate?.textColor?(for: .past)
        } else if !Calendar.current.isDateInToday(day.date) && state == .selected {
            dateLabel.textColor = dayViewAppearanceDelegate?.textColor?(for: state) ?? dateLabel.textColor
        } else {
            dateLabel.textColor = dayViewAppearanceDelegate?.textColor?(for: state) ?? dateLabel.textColor
        }

        backgroundColor = dayViewAppearanceDelegate?.backgroundColor?(for: state) ?? backgroundColor
        layer.borderColor = dayViewAppearanceDelegate?.borderColor?(for: state).cgColor ?? layer.borderColor
        layer.borderWidth = dayViewAppearanceDelegate?.borderWidth?(for: state) ?? dateLabel.layer.borderWidth

        dateLabel.backgroundColor = dayViewAppearanceDelegate?.textBackgroundColor?(for: state) ?? dateLabel.backgroundColor

        updateSupplementaryViews()
    }
    
    private func updateSupplementaryViews() {
        removeAllSupplementaries()
        
        day.supplementaries.forEach { supplementary in
            switch supplementary {
            case .bottomDots(let colors):
                let stack = dotStackView

                colors.forEach { color in
                    let dotView = VADotView(size: dotSize, color: color)
                    stack.addArrangedSubview(dotView)
                }
                let spaceOffset = CGFloat(colors.count - 1) * dotSpacing
                let stackWidth = CGFloat(colors.count) * dotSpacing + spaceOffset
                let verticalOffset = dayViewAppearanceDelegate?.dotBottomVerticalOffset?(for: day.state) ?? 2
                stack.frame = CGRect(x: -10, y: 12, width: stackWidth, height: dotSize)
                stack.center.x = dateLabel.center.x + 16
                addSubview(stack)
                supplementaryViews.append(stack)
            }
        }
    }
    
    private func removeAllSupplementaries() {
        supplementaryViews.forEach { $0.removeFromSuperview() }
        supplementaryViews = []
    }
    
}
