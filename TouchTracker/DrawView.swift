//
//  DrawView.swift
//  TouchTracker
//
//  Created by Jackie Zhang on 16/3/19.
//  Copyright © 2016年 Jackie Zhang. All rights reserved.
//

import UIKit

class DrawView : UIView, UIGestureRecognizerDelegate {
    //MARK: - properties
    var currentLine = [NSValue: Line]()
    var finishedLines = [Line]()
    var selectedLineIndex : Int? {
        didSet {
            if selectedLineIndex == nil {
                let menu = UIMenuController.sharedMenuController()
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    
    @IBInspectable var finishedLineColor : UIColor = UIColor.blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var currentLineColor : UIColor = UIColor.redColor(){
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var lineThickness : CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    //MARK: - init
    required init?(coder aCoder:NSCoder) {
        super.init(coder: aCoder)
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: "doubleTap:")
        doubleTapRecognizer.numberOfTapsRequired = 2
        //TODO: must disable delayTouches and set selectedLineIndex to nil to avoid touchBegin after menu
        //selected cause selected line move. need a more elegent solution

       // doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tap:")
        //tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.requireGestureRecognizerToFail(doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "longPress:")
        addGestureRecognizer(longPressRecognizer)
        
        let moveRecognizer = UIPanGestureRecognizer(target: self, action: "moveLine:")
        moveRecognizer.cancelsTouchesInView = false
        moveRecognizer.delegate = self
        addGestureRecognizer(moveRecognizer)
    }
    
    //MARK: - gesture handler
    //handling all clear
    func doubleTap(gestureRecognizer:UIGestureRecognizer) {
        print ("recognized double tap")
        selectedLineIndex = nil
        currentLine.removeAll(keepCapacity: false)
        finishedLines.removeAll(keepCapacity: false)
        setNeedsDisplay()
    }
    
    //handling line selection
    func tap(gestureRecognizer:UIGestureRecognizer) {
        print("recognized a tap")
        let point = gestureRecognizer.locationInView(self)
        selectedLineIndex = indexOfLineAtPoint(point)
        
        //create menu item
        let menu = UIMenuController.sharedMenuController()
        if selectedLineIndex != nil {
            //make drawView the target of menu action
            becomeFirstResponder()
            //create a new Delete menu item
            let deleteItem = UIMenuItem(title: "Delete", action: "deleteLine:")
            menu.menuItems = [deleteItem]
            //tell menu its location
            menu.setTargetRect(CGRect(x: point.x, y: point.y, width: 2, height: 2), inView: self)
            menu.setMenuVisible(true, animated: true)
        }
        else {
            menu.setMenuVisible(false, animated: true)

        }
        
        
        setNeedsDisplay()
    }
    
    //handling long press moving
    func longPress(gestureRecognizer:UIGestureRecognizer) {
        print ("recognized long press")
        if gestureRecognizer.state == .Began {
            let point = gestureRecognizer.locationInView(self)
            selectedLineIndex = indexOfLineAtPoint(point)
           if selectedLineIndex != nil {
                currentLine.removeAll(keepCapacity: false)
            }
        } else if gestureRecognizer.state == .Ended {
            selectedLineIndex = nil
        }
        setNeedsDisplay()
    }
    

    
    //MARK: - draw events
    func strokeLine(line: Line) {
        let path = UIBezierPath()
        path.lineWidth = lineThickness
        path.lineCapStyle = .Round
        path.moveToPoint(line.begin)
        path.addLineToPoint(line.end)
        path.stroke()
        
    }
    
    override func drawRect(rect: CGRect) {
        
        //draw finished lines
        finishedLineColor.setStroke()
        for line in finishedLines {
            strokeLine(line)
        }
        //draw current lines
        currentLineColor.setStroke()
        for (_, line) in currentLine {
            strokeLine(line)
        }
        
        //draw selected line
        if let index = selectedLineIndex {
            UIColor.greenColor().setStroke()
            let selectedLine = finishedLines[index]
            strokeLine(selectedLine)
        }
    }
    
    func indexOfLineAtPoint(point: CGPoint) -> Int? {
        //Find a line close to point
        for (index, line) in finishedLines.enumerate() {
            let begin = line.begin
            let end = line.end
            
            //check a few points on the line
            for t in CGFloat(0).stride(to: 1.0, by: 0.05) {
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                if hypot(x - point.x, y - point.y) < 20 {
                    return index
                }
            }
        }
    
        return nil
            
        
    }
    
    func deleteLine(sender: AnyObject) {
        //remove the selected line from finishedLines
        if let index = selectedLineIndex {
            finishedLines.removeAtIndex(index)
            selectedLineIndex = nil
            
            setNeedsDisplay()
        }
    }
    
    //handling moving
    func moveLine(gestureRecognizer:UIPanGestureRecognizer) {
        print ("recognized a pan")
        //if a line is selected
        if let index = selectedLineIndex {
            if gestureRecognizer.state == .Changed {
                let transition = gestureRecognizer.translationInView(self)
                //add the transition value to selected line's position
                finishedLines[index].begin.x += transition.x
                finishedLines[index].begin.y += transition.y
                finishedLines[index].end.x += transition.x
                finishedLines[index].end.y += transition.y
                //use the delta value compared to the last call value
                gestureRecognizer.setTranslation(CGPoint.zero, inView: self)
                
                setNeedsDisplay()
                
            } else {
                return
            }
            
        }
        
    }
    //MARK: - touch events
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print (__FUNCTION__)
        selectedLineIndex = nil
        for touch in touches {
            let location = touch.locationInView(self)
            let newLine = Line(begin: location, end: location)
            let key = NSValue(nonretainedObject: touch)
            currentLine[key] = newLine
        }
        
        setNeedsDisplay()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print (__FUNCTION__)
        for touch in touches {
            let location = touch.locationInView(self)
            let key = NSValue(nonretainedObject: touch)
            currentLine[key]?.end = location
        }
        
        setNeedsDisplay()
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print (__FUNCTION__)
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            if var line = currentLine[key] {
                line.end = touch.locationInView(self)
                finishedLines.append(line)
                currentLine.removeValueForKey(key)
            }
        }
        
        setNeedsDisplay()
        
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        print (__FUNCTION__)
        currentLine.removeAll()
        setNeedsDisplay()
    }
    
    //MARK: - delegates
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    //MARK: - other override
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
}
