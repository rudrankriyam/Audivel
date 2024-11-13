import Foundation

/// A configuration manager that handles environment variables for the application.
struct Configuration {
  /// Shared instance for accessing configuration values
  static let shared = Configuration()
  
  /// The Play.ht API key loaded from environment variables
  let playHTAPIKey: String
  
  /// The Play.ht User ID loaded from environment variables
  let playHTUserID: String
  
  private init() {
    // Load environment variables from .env file
    Self.loadEnvironment()
    
    // Initialize with environment variables or empty strings if not found
    self.playHTAPIKey = ProcessInfo.processInfo.environment["PLAYHT_API_KEY"] ?? ""
    self.playHTUserID = ProcessInfo.processInfo.environment["PLAYHT_USER_ID"] ?? ""
  }
  
  /// Loads the environment variables from the .env file
  private static func loadEnvironment() {
    guard let envPath = Bundle.main.path(forResource: ".env", ofType: nil) else {
      print("⚠️ .env file not found")
      return
    }
    
    do {
      let envContent = try String(contentsOfFile: envPath, encoding: .utf8)
      let envVars = envContent.components(separatedBy: .newlines)
      
      for var line in envVars {
        line = line.trimmingCharacters(in: .whitespaces)
        
        // Skip comments and empty lines
        if line.isEmpty || line.hasPrefix("#") {
          continue
        }
        
        let parts = line.split(separator: "=", maxSplits: 1)
        if parts.count == 2 {
          let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
          let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
          setenv(key, value, 1)
        }
      }
    } catch {
      print("⚠️ Error loading .env file: \(error)")
    }
  }
} 
