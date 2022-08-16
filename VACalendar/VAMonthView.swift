//
//  VAMonthView.swift
//  VACalendar
//
//  Created by Anton Vodolazkyi on 20.02.18.
//  Copyright © 2018 Vodolazkyi. All rights reserved.
//

import UIKit

protocol VAMonthViewDelegate: class {
    func dayStateChanged(_ day: VADay, in month: VAMonth)
}

@objc
public protocol VAMonthViewAppearanceDelegate: class {
    @objc optional func leftInset() -> CGFloat
    @objc optional func rightInset() -> CGFloat
    @objc optional func verticalMonthTitleFont() -> UIFont
    @objc optional func verticalWeekTitleFont() -> UIFont
    @objc optional func verticalMonthTitleColor() -> UIColor
    @objc optional func verticalCurrentMonthTitleColor() -> UIColor
    @objc optional func verticalMonthDateFormater() -> DateFormatter
    @objc optional func seperatorColor() -> UIColor
}

class VAMonthView: UIView {
    
    var numberOfWeeks: Int {
        return month.numberOfWeeks
    }
    
    var isDrawn: Bool {
        return !weekViews.isEmpty
    }
    
    var scrollDirection: VACalendarScrollDirection {
        return (superview as? VACalendarView)?.scrollDirection ?? .horizontal
    }
    
    var monthVerticalHeaderHeight: CGFloat {
        return (superview as? VACalendarView)?.monthVerticalHeaderHeight ?? 0.0
    }
    
    var superviewWidth: CGFloat {
        return superview?.frame.width ?? 0
    }
    
    weak var monthViewAppearanceDelegate: VAMonthViewAppearanceDelegate? {
        return (superview as? VACalendarView)?.monthViewAppearanceDelegate
    }
    
    weak var dayViewAppearanceDelegate: VADayViewAppearanceDelegate? {
        return (superview as? VACalendarView)?.dayViewAppearanceDelegate
    }
    
    weak var delegate: VAMonthViewDelegate?

    let month: VAMonth
    
    private let showDaysOut: Bool
    private var monthLabel: UILabel?
    private var weekViews = [VAWeekView]()
    private let weekHeight: CGFloat
    private var viewType: VACalendarViewType
    private var weekDaysView: VAWeekDaysView?

    let defaultCalendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        return calendar
    }()

    init(month: VAMonth,
         showDaysOut: Bool,
         weekHeight: CGFloat,
         viewType: VACalendarViewType,
         backgroundColors: UIColor) {
        self.month = month
        self.showDaysOut = showDaysOut
        self.weekHeight = weekHeight
        self.viewType = viewType
        
        super.init(frame: .zero)
        
        backgroundColor = backgroundColors
        layer.cornerRadius = 6.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupWeeksView(with type: VACalendarViewType) {
        guard isDrawn == false else { return }
    
        self.viewType = type
        
        if scrollDirection == .vertical {
            setupMonthLabel()
            setupWeekView()
        }

        self.weekViews = []

        month.weeks.enumerated().forEach { index, week in
            let weekView = VAWeekView(week: week, showDaysOut: showDaysOut)
            weekView.delegate = self
            self.weekViews.append(weekView)
            self.addSubview(weekView)
        }
        
        draw()
    }
    
    func clean() {
        monthLabel = nil
        weekDaysView = nil
        weekViews = []
        subviews.forEach { $0.removeFromSuperview() }
    }
    
    func week(with date: Date) -> VAWeekView? {
        return weekViews.first(where: { $0.contains(date: date) })
    }

    private func draw() {
        let leftInset = monthViewAppearanceDelegate?.leftInset?() ?? 0
        let rightInset = monthViewAppearanceDelegate?.rightInset?() ?? 0
        let initialOffsetY = self.weekDaysView?.frame.maxY ?? 10
        let weekViewWidth = self.frame.width - (leftInset + rightInset)
        
        var x: CGFloat = leftInset
        var y: CGFloat = initialOffsetY

        weekViews.enumerated().forEach { index, week in
            switch viewType {
            case .month:
                week.frame = CGRect(
                    x: leftInset,
                    y: y,
                    width: weekViewWidth,
                    height: self.weekHeight
                )
                y = week.frame.maxY
                
            case .week:
                let width = self.superviewWidth - (leftInset + rightInset)

                week.frame = CGRect(
                    x: x,
                    y: initialOffsetY,
                    width: width,
                    height: self.weekHeight
                )
                x = week.frame.maxX + (leftInset + rightInset)
            }
            week.setupDays()
        }
    }
    
    private func setupMonthLabel() {
        let textColor = month.isCurrent ? monthViewAppearanceDelegate?.verticalCurrentMonthTitleColor?() :
            monthViewAppearanceDelegate?.verticalMonthTitleColor?()
				let textFormatter = monthViewAppearanceDelegate?.verticalMonthDateFormater?() ?? VAFormatters.monthFormatter
        
        monthLabel = UILabel()
        monthLabel?.frame = CGRect(x: 0, y: 12, width: self.frame.width, height: 24)
        monthLabel?.text = textFormatter.string(from: month.date)
        monthLabel?.textColor = textColor ?? monthLabel?.textColor
        monthLabel?.textAlignment = .center
        monthLabel?.font = monthViewAppearanceDelegate?.verticalMonthTitleFont?() ?? monthLabel?.font
        monthLabel?.sizeToFit()
        monthLabel?.center.x = center.x
        addSubview(monthLabel ?? UIView())
    }

    private func setupWeekView() {
        weekDaysView = VAWeekDaysView()
        weekDaysView?.appearance = VAWeekDaysViewAppearance(symbolsType: .veryShort,
                                                            weekDayTextColor: (monthViewAppearanceDelegate?.verticalMonthTitleColor?() ?? monthLabel?.textColor) ?? .black,
                                                            weekDayTextFont: (monthViewAppearanceDelegate?.verticalWeekTitleFont?() ?? monthLabel?.font) ?? .systemFont(ofSize: 16.0),
                                                            separatorBackgroundColor: (monthViewAppearanceDelegate?.seperatorColor?() ?? monthLabel?.textColor) ?? .black,
                                                            calendar: defaultCalendar)
        let leftInset = monthViewAppearanceDelegate?.leftInset?() ?? 0
        let rightInset = monthViewAppearanceDelegate?.rightInset?() ?? 0
        let weekViewWidth = self.frame.width - (leftInset + rightInset)
        weekDaysView?.frame = CGRect(x: 0, y: (monthLabel?.frame.origin.y ?? 10.0) + (monthLabel?.frame.height ?? 70.0) + 12,
                                     width: weekViewWidth,
                                     height: 50.0)
        addSubview(weekDaysView ?? UIView())
    }
    
}

extension VAMonthView: VAWeekViewDelegate {
    
    func dayStateChanged(_ day: VADay, in week: VAWeek) {
        delegate?.dayStateChanged(day, in: month)
    }
    
}
