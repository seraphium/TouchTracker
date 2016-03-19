//
//  DrawView.swift
//  TouchTracker
//
//  Created by Jackie Zhang on 16/3/19.
//  Copyright © 2016年 Jackie Zhang. All rights reserved.
//

import UIKit

class DrawView : UIView {
    var currentLine = [NSValue: Line]()
    var finishedLines = [Line]()
    
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
    
    required init?(coder aCoder:NSCoder) {
        super.init(coder: aCoder)
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: "doubleTap:")
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
    }
    
    func doubleTap(gestureRecognizer:UIGestureRecognizer) {
        print ("recognized double tap")
        currentLine.removeAll(keepCapacity: false)
        finishedLines.removeAll(keepCapacity: false)
        setNeedsDisplay()
    }
    
    func strokeLine(line: Line) {
        let path = UIBezierPath()
        path.lineWidth = lineThickness
        path.lineCapStyle = .Round
        path.moveToPoint(line.begin)
        path.addLineToPoint(line.end)
        path.stroke()
        
    }
    
    override func drawRect(rect: CGRect) {
        //draw finished lines in black
        finishedLineColor.setStroke()
        for line in finishedLines {
            strokeLine(line)
        }
        
        currentLineColor.setStroke()
        for (_, line) in currentLine {
            strokeLine(line)
        }
        
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        print (__FUNCTION__)
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
    
    
    
}
