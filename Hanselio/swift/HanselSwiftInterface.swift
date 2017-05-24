//
//  HanselSwiftInterface.swift
//  PebbletraceSwiftTest
//
//  Created by Prabodh Prakash on 19/12/16.
//  Copyright © 2016 lohabhaiya. All rights reserved. Dummy file
//

import Foundation
import Hanselio

protocol HanselProviderProtocol
{
    func callAnything<T>(selfRef: T, functionName: String, argsArr: Array<Any>) -> Any?
    func getVar<T>(selfRef: T, varName: String) -> Any?
    func setVar<T>(selfRef: T, varName: String, varValue: Any)
}

class HanselSwiftInterface
{
    static func unwrap(_ arr: Array<Any>) -> Array<Any>
    {
        var returnArr = Array<Any>()
        
        for obj in arr
        {
            if obj is Dictionary<String, Any>
            {
                let dict = obj as! Dictionary<String, Any>
                if  dict["__dictType"] != nil
                {
                    if dict["__dictType"] as! String == "hWrap"
                    {
                        returnArr.append(dict["__orgObj"]!)
                    }
                    else if dict["__dictType"] as! String == "hNWrap"
                    {
                        let returnObj = dict["__obj"]!
                        if returnObj is HanselSwiftTypeWrapper
                        {
                            returnArr.append((returnObj as! HanselSwiftTypeWrapper).getObject())
                        }
                        else
                        {
                            returnArr.append(dict["__obj"]!)
                        }
                    }
                    else
                    {
                        returnArr.append(dict)
                    }
                }
                else if dict["__obj"] != nil
                {
                    returnArr.append(HanselCrashReporter.tryUnwrapping(dict["__obj"]))
                }
                else
                {
                    returnArr.append(dict)
                }
            }
            else if obj is HanselSwiftTypeWrapper
            {
                returnArr.append((obj as! HanselSwiftTypeWrapper).getObject())
            }
            else
            {
                returnArr.append(obj)
            }
        }

        return returnArr
    }
    
    static func wrapWithClass<T>(_ value: T) -> (Any, String, Mirror)
    {
        let mirrorType = Mirror(reflecting: value)
        if let displayStyle = mirrorType.displayStyle
        {
            if displayStyle == Mirror.DisplayStyle.class
            {
                if !(value is NSObject)
                {
                    return (HanselSwiftTypeWrapper(object: value, className: "\(T.self)")!, "HanselSwiftTypeWrapper", mirrorType)
                }
            }
        }
        
        return (value, "\(T.self)", mirrorType)
    }
    
    static func forceWrap<T>(_ value: T) -> Any
    {
        return HanselSwiftTypeWrapper(object: value, className: "HanselSwiftWrapper")!
    }
    
    static func wrap<T>(_ value: T) -> Any
    {
        let mirrorType = Mirror(reflecting: value)
        if let displayStyle = mirrorType.displayStyle
        {
            if displayStyle == Mirror.DisplayStyle.class
            {
                if !(value is NSObject)
                {
                    return HanselSwiftTypeWrapper(object: value, className: "HanselSwiftTypeWrapper")!
                }
            }
        }
        
        return value
    }
    
    static func isPatchEnabled(function: String) -> Bool
    {
        if (HanselCrashReporter.isPatchEnabled(function))
        {
            return true
        }
        else
        {
            return false;
        }
    }
    
    static func invokePatch<T>(arr: Array<Any>, selfRef: Any, className: String, functionName: String, closure: @escaping (NSArray!)->T,callAnythingClosure: @escaping (Array<Any>) -> Any) -> T
    {
        var arrModified = arr
        var arrWrapper = [NSString](repeating: "wrap" as NSString, count: arr.count)
        var classArr = [String](repeating:"", count: arr.count)
        
        for i in 0  ..< arr.count
        {
            classArr[i] = String(describing: Mirror(reflecting: arr[i]).subjectType)
            if arr[i] is NSObject
            {
                arrWrapper[i] = "nowrap" as NSString
            }
            else
            {
                arrWrapper[i] = "wrap" as NSString
            }
            
            arrModified[i] = wrap(arr[i])
        }
        
        let bundleName: String = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let updatedClassName: String = "\(bundleName).\(className)"
        
        let selfParam = ["__obj": forceWrap(selfRef), "__clsName": "HanselSwiftTypeWrapper"]
        
        let value = HanselCrashReporter.invokePatch(withArgumentsArray: arrModified, modifierArray: arrWrapper, classArr: classArr, className: updatedClassName, functionName: functionName, closure:
            {
                args in
                let something = unwrap(args!)
                let returnValue = closure(something as NSArray!)
                var isWrapped: NSString = "wrap"
                if returnValue is NSObject
                {
                    isWrapped = "nowrap" as NSString
                }
                else
                {
                    isWrapped = "wrap" as NSString
                }
                
                let returnType = wrapWithClass(returnValue)
                
                return ["__obj": returnType.0, "__clsName": returnType.1, "__isWrapped": isWrapped];
        },
                                                    callAnythingClosure:
            {
                obj in let obAny = obj!; let ob = obAny[0];
                
                if ob is HanselSwiftTypeWrapper
                {
                    let finalObj = (ob as! HanselSwiftTypeWrapper).getObject();
                    let something = unwrap(obj?[2] as! Array<Any>)
                    
                    let result = callAnythingClosure([finalObj!, obj?[1] as! String, something as NSArray!])
                    
                    var isWrapped: NSString = "wrap"
                    if result is NSObject
                    {
                        isWrapped = "nowrap" as NSString
                    }
                    else
                    {
                        isWrapped = "wrap" as NSString
                    }
                    
                    let returnType = wrapWithClass(result)
                    
                    if (returnType.2.subjectType == Swift.Int
                        || returnType.2.subjectType == Swift.Int8
                        || returnType.2.subjectType == Swift.Int16
                        || returnType.2.subjectType == Swift.Int32
                        || returnType.2.subjectType == Swift.Int64
                        || returnType.2.subjectType == Swift.UInt
                        || returnType.2.subjectType == Swift.UInt8
                        || returnType.2.subjectType == Swift.UInt16
                        || returnType.2.subjectType == Swift.UInt32
                        || returnType.2.subjectType == Swift.UInt64
                        || returnType.2.subjectType == Swift.Float
                        || returnType.2.subjectType == Swift.Float32
                        || returnType.2.subjectType == Swift.Float64
                        || returnType.2.subjectType == Swift.Double
                        || returnType.2.subjectType == Swift.Bool
                        )
                    {
                        return ["__obj": returnType.0, "__isWrapped": "original"];
                    }
                    
                    return ["__obj": returnType.0, "__clsName": returnType.1, "__isWrapped": isWrapped];
                }
                else
                {
                    let finalObj = obAny[0] as Any;
                    
                    let something = unwrap(obj?[2] as! Array<Any>)
                    
                    let result = callAnythingClosure([finalObj, obAny[1] as! String, something as NSArray!])
                    
                    var isWrapped: NSString = "wrap"
                    if result is NSObject
                    {
                        isWrapped = "nowrap" as NSString
                    }
                    else
                    {
                        isWrapped = "wrap" as NSString
                    }
                    
                    let returnType = wrapWithClass(result)
                    
                    if (returnType.2.subjectType == Swift.Int
                        || returnType.2.subjectType == Swift.Int8
                        || returnType.2.subjectType == Swift.Int16
                        || returnType.2.subjectType == Swift.Int32
                        || returnType.2.subjectType == Swift.Int64
                        || returnType.2.subjectType == Swift.UInt
                        || returnType.2.subjectType == Swift.UInt8
                        || returnType.2.subjectType == Swift.UInt16
                        || returnType.2.subjectType == Swift.UInt32
                        || returnType.2.subjectType == Swift.UInt64
                        || returnType.2.subjectType == Swift.Float
                        || returnType.2.subjectType == Swift.Float32
                        || returnType.2.subjectType == Swift.Float64
                        || returnType.2.subjectType == Swift.Double
                        || returnType.2.subjectType == Swift.Bool
                        )
                    {
                        return ["__obj": returnType.0, "__isWrapped": "original"];
                    }
                    
                    return ["__obj": returnType.0, "__clsName": returnType.1, "__isWrapped": isWrapped];
                    
                }
        }, selfRef: selfParam)
        
        if (T.self == Int.self || T.self == Int?.self)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                return wObj as! T
            }
            
            return value?.toNumber() as! T
        }
        else if (T.self == UInt.self || T.self == UInt?.self)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                return wObj as! T
            }
            
            return value?.toNumber() as! T
        }
        else if (T.self == Int8.self || T.self == Int8?.self)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                return wObj as! T
            }
            
            return value?.toNumber() as! T
        }
        else if (T.self == UInt8.self || T.self == UInt8?.self)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                return wObj as! T
            }
            
            return value?.toNumber() as! T
        }
        else if (T.self == Int16.self || T.self == Int16?.self)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                return wObj as! T
            }
            
            return value?.toNumber() as! T
        }
        else if (T.self == UInt16.self || T.self == UInt16?.self)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                return wObj as! T
            }
            
            return value?.toNumber() as! T
        }
        else if (T.self == Int32.self || T.self == Int32?.self)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                return wObj as! T
            }
            
            return value?.toInt32() as! T
        }
        else if (T.self == UInt32.self || T.self == UInt32?.self)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                return wObj as! T
            }
            
            return value?.toUInt32() as! T
        }
        else if (T.self == Int64.self || T.self == Int64?.self)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                return wObj as! T
            }
            
            return value?.toNumber() as! T
        }
        else if (T.self == UInt64.self || T.self == UInt64?.self)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                return wObj as! T
            }
            
            return value?.toNumber() as! T
        }
        else if (T.self == Float.self || T.self == Float?.self)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                return wObj as! T
            }
            
            return value?.toNumber() as! T
        }
        else if (T.self == Double.self || T.self == Double?.self)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                return wObj as! T
            }
            
            return value?.toDouble() as! T
        }
        else if (T.self == Bool.self || T.self == Bool?.self)
        {
            return value?.toBool() as! T
        }
        else if (T.self == String.self || T.self == String?.self)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                return wObj as! T
            }
            
            return value?.toString() as! T
        }
        else if (T.self == Void.self)
        {
            let x: Void
            return x as! T
        }
        else if (T.self == Swift.UnsafePointer<Swift.Int8>)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                if wObj is NSValue
                {
                    let nsVal = (wObj as! NSValue)
                    let bytesPointer = nsVal.pointerValue;
                    
                    let finalPtr =  UnsafePointer.init(bytesPointer?.assumingMemoryBound(to: Int8.self)) as! T
                    return finalPtr
                }
                else
                {
                    return wObj as! T
                }
            }
            
            return retObj as! T
        }
        else if (T.self == Swift.UnsafePointer<Swift.Int16>)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                if wObj is NSValue
                {
                    let nsVal = (wObj as! NSValue)
                    let bytesPointer = nsVal.pointerValue;
                    
                    let finalPtr =  UnsafePointer.init(bytesPointer?.assumingMemoryBound(to: Int16.self)) as! T
                    return finalPtr
                }
                else
                {
                    return wObj as! T
                }
            }
            
            return retObj as! T
        }
        else if (T.self == Swift.UnsafePointer<Swift.Int32>)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                if wObj is NSValue
                {
                    let nsVal = (wObj as! NSValue)
                    let bytesPointer = nsVal.pointerValue;
                    
                    let finalPtr =  UnsafePointer.init(bytesPointer?.assumingMemoryBound(to: Int32.self)) as! T
                    return finalPtr
                }
                else
                {
                    return wObj as! T
                }
            }
            
            return retObj as! T
        }
        else if (T.self == Swift.UnsafePointer<Swift.UInt>)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                if wObj is NSValue
                {
                    let nsVal = (wObj as! NSValue)
                    let bytesPointer = nsVal.pointerValue;
                    
                    let finalPtr =  UnsafePointer.init(bytesPointer?.assumingMemoryBound(to: UInt.self)) as! T
                    return finalPtr
                }
                else
                {
                    return wObj as! T
                }
            }
            
            return retObj as! T
        }
        else if (T.self == Swift.UnsafePointer<Swift.UInt8>)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                if wObj is NSValue
                {
                    let nsVal = (wObj as! NSValue)
                    let bytesPointer = nsVal.pointerValue;
                    
                    let finalPtr =  UnsafePointer.init(bytesPointer?.assumingMemoryBound(to: UInt8.self)) as! T
                    return finalPtr
                }
                else
                {
                    return wObj as! T
                }
            }
            
            return retObj as! T
        }
        else if (T.self == Swift.UnsafePointer<Swift.UInt16>)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                if wObj is NSValue
                {
                    let nsVal = (wObj as! NSValue)
                    let bytesPointer = nsVal.pointerValue;
                    
                    let finalPtr =  UnsafePointer.init(bytesPointer?.assumingMemoryBound(to: UInt16.self)) as! T
                    return finalPtr
                }
                else
                {
                    return wObj as! T
                }
            }
            
            return retObj as! T
        }
        else if (T.self == Swift.UnsafePointer<Swift.UInt32>)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                if wObj is NSValue
                {
                    let nsVal = (wObj as! NSValue)
                    let bytesPointer = nsVal.pointerValue;
                    
                    let finalPtr =  UnsafePointer.init(bytesPointer?.assumingMemoryBound(to: UInt32.self)) as! T
                    return finalPtr
                }
                else
                {
                    return wObj as! T
                }
            }
            
            return retObj as! T
        }
        else if (T.self == Swift.UnsafePointer<Swift.UInt64>)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                if wObj is NSValue
                {
                    let nsVal = (wObj as! NSValue)
                    let bytesPointer = nsVal.pointerValue;
                    
                    let finalPtr =  UnsafePointer.init(bytesPointer?.assumingMemoryBound(to: UInt64.self)) as! T
                    return finalPtr
                }
                else
                {
                    return wObj as! T
                }
            }
            
            return retObj as! T
        }
        else if (T.self == Swift.UnsafePointer<Swift.Float>)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                if wObj is NSValue
                {
                    let nsVal = (wObj as! NSValue)
                    let bytesPointer = nsVal.pointerValue;
                    
                    let finalPtr =  UnsafePointer.init(bytesPointer?.assumingMemoryBound(to: Float.self)) as! T
                    return finalPtr
                }
                else
                {
                    return wObj as! T
                }
            }
            
            return retObj as! T
        }
        else if (T.self == Swift.UnsafePointer<Swift.Double>)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                if wObj is NSValue
                {
                    let nsVal = (wObj as! NSValue)
                    let bytesPointer = nsVal.pointerValue;
                    
                    let finalPtr =  UnsafePointer.init(bytesPointer?.assumingMemoryBound(to: Double.self)) as! T
                    return finalPtr
                }
                else
                {
                    return wObj as! T
                }
            }
            return retObj as! T
        }
        else if (T.self == Swift.UnsafePointer<Swift.Float32>)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                if wObj is NSValue
                {
                    let nsVal = (wObj as! NSValue)
                    let bytesPointer = nsVal.pointerValue;
                    
                    let finalPtr =  UnsafePointer.init(bytesPointer?.assumingMemoryBound(to: Float32.self)) as! T
                    return finalPtr
                }
                else
                {
                    return wObj as! T
                }
            }
            
            return retObj as! T
        }
        else if (T.self == Swift.UnsafePointer<Swift.Float64>)
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                if wObj is NSValue
                {
                    let nsVal = (wObj as! NSValue)
                    let bytesPointer = nsVal.pointerValue;
                    
                    let finalPtr =  UnsafePointer.init(bytesPointer?.assumingMemoryBound(to: Float64.self)) as! T
                    return finalPtr
                }
                else
                {
                    return wObj as! T
                }
            }
            
            return retObj as! T
        }
        else
        {
            let retObj = value?.toObject()
            
            if retObj is Dictionary<String, Any>
            {
                let obj = (retObj as! Dictionary<String, Any>)
                let wObj = obj["__obj"]
                
                if (wObj == nil)
                {
                    return obj as! T;
                }
                
                if wObj is HanselSwiftTypeWrapper
                {
                    return (wObj as! HanselSwiftTypeWrapper).getObject() as! T
                }
                
                return (wObj as AnyObject) as! T
            }
            else if retObj is HanselSwiftTypeWrapper
            {
                return (retObj as! HanselSwiftTypeWrapper).getObject() as! T
            }
            
            return retObj as! T;
        }
    }
}
