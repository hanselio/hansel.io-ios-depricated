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
    static func isPatchEnabled(function: String) -> Bool
    {
        return true
    }
    
    static func invokePatch<T>(arr: Array<Any>, selfRef: Any, className: String, functionName: String, closure: @escaping (NSArray!)->T,callAnythingClosure: @escaping (Array<Any>) -> Any) -> Void
    {
        return;
    }
}
