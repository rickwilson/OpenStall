import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2)
    var timer:NSTimer?
    var open:Bool = true {
        didSet {
            if(open) {
                statusItem.button?.image = NSImage(named: "StatusBarButtonImage-open")
            }
            else {
                statusItem.button?.image = NSImage(named: "StatusBarButtonImage-closed")
            }
        }
    }
    var online:Bool = true {
        didSet {
            if(!online) {
                self.statusItem.button?.image = NSImage(named: "StatusBarButtonImage-offline")
            }
        }
    }
    let requestString = "https://logtailer.herokuapp.com/api/v1/status"
    var session: NSURLSession!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusBarButtonImage-offline")
            button.action = Selector("updateStall:")
        }
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: config, delegate: nil, delegateQueue: nil)
        
        timer = NSTimer.scheduledTimerWithTimeInterval(15, target: self, selector: "checkState:", userInfo: nil, repeats: true)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func updateStall(sender: AnyObject) {
        if online {
            if open {
                print("Stall is OPEN")
            }
            else {
                print("Stall is CLOSED")
            }
        } else {
            print("No Connected to Service")
        }

    }
    
    func checkState(timer: NSTimer) {
        setStatusFromLogTailerService()
    }
    
    func setStatusFromLogTailerService() {
        if let url = NSURL(string: requestString) {
            let req = NSMutableURLRequest(URL: url)
            req.HTTPMethod = "POST"
            let dataTask = session.dataTaskWithRequest(req) {
                (data, response, error) in
                if data != nil {
                    do {
                        let jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
                        
                        guard let json = jsonObject as? [String: AnyObject] else {
                            print("Error fetching logTailer: jsonObject nil")
                            self.online = false
                            return
                        }
                        
                        if let openStatus = json["stall_open"] as? Bool {
                            self.open = openStatus
                            if !self.online {
                                self.online = true
                            }
                        } else {
                            print("Error fetching logTailer: json[\"stall_open\"] nil")
                            self.online = false
                        }
                    } catch _ {
                        if let error = error {
                            print("Error fetching logTailer: \(error.localizedDescription)")
                        }
                        else {
                            print("Unknown error fetching logTailer")
                        }
                        self.online = false
                    }
                } else {
                    print("Error fetching logTailer: data nil")
                    self.online = false
                }
            }
            dataTask.resume()
        } else {
            print("Error fetching logTailer: url nil")
            self.online = false
        }
    }
}

