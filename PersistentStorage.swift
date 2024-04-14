//
//  PersistentStorage.swift
//  VHIRegister
//
//  Created by Shivanshu Verma on 01/01/24.
//

import Foundation
import CoreData

final class PersistentStorage {
    private init() {}
    static let shared = PersistentStorage()

    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "VHIRegister")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                print(storeDescription)
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Application Support Directory
    /// Returns the URL of the application support directory.
    ///
    /// This lazy variable is initialized with the first URL in the array of URLs obtained
    /// from the FileManager for the `.applicationSupportDirectory` in the `.userDomainMask`.
    ///
    /// - Returns: The URL of the application support directory.
    lazy var applicationSupportDirectory: URL = {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return urls as URL
    }()

    // MARK: - Core Data Saving support
    lazy var context = persistentContainer.viewContext
    func saveContext () {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

extension PersistentStorage {
    // MARK: - Fetch Managed Objects List Using newBackgroundContext
    /// Fetches `NSManagedObject` instances of a specified type in a background context.
    ///
    /// This function creates a new background context and performs a fetch request for
    /// managed objects of the specified type. The results are returned asynchronously
    /// through the completion handler. It automatically merges changes from the parent context
    /// to ensure data consistency.
    ///
    /// - Parameters:
    ///   - managedObject: The `NSManagedObject` subclass type to be fetched.
    ///   - completion: The closure to call with the fetched objects (or `nil` if none found) upon completion.
    func fetchBackgroundManagedObjects<T: NSManagedObject>(managedObject: T.Type, completion: @escaping ([T]?) -> Void) {
        /// Create a new background managed object context
        let context = self.persistentContainer.newBackgroundContext()
        /// ensure the background context stays up to date with changes
        context.automaticallyMergesChangesFromParent = true
        /// Perform operations on the background context `asynchronously`
        context.perform {
            do {
                /// Attempts to fetch objects from the context and retrieves the values
                if let result = try context.fetch(managedObject.fetchRequest()) as? [T] {
                    /// Call the success completion handler
                    completion(result)
                } else {
                    /// `nil`, if no  object is found.
                    completion(nil)
                }
            } catch let error {
                /// Catches and prints any errors that occur during the fetch request.
                print("Error while fetching the values: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    // MARK: - Fetch Managed Objects List Using context
    /// Fetches `NSManagedObject` instances of a specified type from the main context.
    ///
    /// This function attempts to fetch objects of the specified `NSManagedObject` subclass type
    /// from the main managed object context. It returns an array of fetched objects if successful,
    /// or `nil` if no objects are found or an error occurs.
    ///
    /// - Parameter managedObject: The `NSManagedObject` subclass type to be fetched.
    /// - Returns: An array of fetched objects of the specified type, or `nil` if none found or in case of an error.
    func fetchManagedObjects<T: NSManagedObject>(managedObject: T.Type) -> [T]? {
        do {
            /// Attempts to fetch objects from the context and retrieves the values
            if let result = try self.context.fetch(managedObject.fetchRequest()) as? [T] {
                /// return the fetch data values
                return result
            } else {
                /// Returns `nil`, if no object is found.
                return nil
            }
        } catch let error {
            /// Catches and prints any errors that occur during the fetch request.
            print("Error while fetching the values: \(error.localizedDescription)")
        }
        /// Returns nil, if an error occurs during the fetch request or any other unexpected condition arises.
        return nil
    }
}

extension PersistentStorage {
    // MARK: - Fetch Single Managed Object
    /// Fetches a single `NSManagedObject` instance of a specified type based on a specific attribute and identifier.
    ///
    /// This function creates a fetch request for the specified `NSManagedObject` subclass (type T)
    /// with a predicate filtering the results based on a given attribute name and its corresponding identifier.
    /// It returns the first object that matches the criteria, or `nil` if no matching object is found or in case of an error.
    ///
    /// - Parameters:
    ///   - name: The name of the `attribute` to be used in the predicate for filtering.
    ///   - identifier: The `identifier` value to be matched against the `specified attribute`.
    ///   - type: The `NSManagedObject` subclass type to be fetched.
    /// - Returns: An instance of the specified `NSManagedObject` subclass that matches the given criteria, or `nil` if none found or in case of an error.
    public func fetchManagedObject<T: NSManagedObject>(attribute name: String, by identifier: String, type: T.Type) -> T? {
        /// Creates a fetch request object of type NSFetchRequest<T> and initialises it with the `entity name` obtained from the generic type T.
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        /// Creates a predicate object that specifies a condition where the `name` attribute of the entity is equal to the provided `identifier value`.
        let predicate = NSPredicate(format: "\(name)==%@", identifier as CVarArg)
        /// Assigns the created predicate to the fetch request object's predicate property.
        fetchRequest.predicate = predicate
        do {
            /// Attempts to fetch objects from the context that match the fetch request's predicate,
            /// and retrieves the first object from the result array if any.
            if let result = try self.context.fetch(fetchRequest).first {
                /// Returns the matching object as the result of the function.
                return result
            } else {
                /// Returns nil if no matching object is found.
                return nil
            }
        } catch let error {
            ///  Catches and prints any errors that occur during the fetch request.
            print("Error while fetching the single managed object: \(error.localizedDescription)")
        }
        /// Returns nil, if an error occurs during the fetch request or any other unexpected condition arises.
        return nil
    }
}
extension PersistentStorage {
    // MARK: - Does Record Exist
    /// Checks if a record exists in the database for a specified `NSManagedObject` type based on a specific attribute and identifier.
    ///
    /// This function verifies the existence of a record in the persistent store for a given `NSManagedObject` subclass (type T).
    /// It utilizes a fetch request with a predicate that filters results based on a specified attribute name and its corresponding identifier.
    /// The function returns `true` if at least one matching record is found, otherwise returns `false`.
    ///
    /// - Parameters:
    ///   - name: The name of the attribute to be used in the predicate for filtering.
    ///   - identifier: The identifier value to be matched against the specified attribute.
    ///   - type: The `NSManagedObject` subclass type to be checked.
    ///   - context: The `NSManagedObjectContext` to perform the request in. By default, it uses the shared context from `PersistentStorage`.
    /// - Returns: A Boolean value indicating whether at least one record exists matching the criteria.
    func doesRecordExist<T: NSManagedObject>(attribute name: String, by identifier: String, type: T.Type, context: NSManagedObjectContext = PersistentStorage.shared.context) -> Bool {
        /// Creates a fetch request object of type NSFetchRequest<T> and initialises it with the `entity name` obtained from the generic type T.
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        /// Creates a predicate object that specifies a condition where the `name` attribute of the entity is equal to the provided `id value`.
        let predicate = NSPredicate(format: "\(name)==%@", identifier as CVarArg)
        /// Assigns the created predicate to the fetch request
        fetchRequest.predicate = predicate
        do {
            /// Count the number of objects that match the fetch request
            let count = try context.count(for: fetchRequest)
            /// Return `true` if the count is more than 0, indicating that at least one matching record exists/
            /// otherwise returns `false`.
            return count > 0
        } catch {
            ///  Catches and prints any errors that occur during the fetch request.
            print("Error: while checking the record exists: \(error.localizedDescription)")
            return false
        }
    }
}
extension PersistentStorage {
    // MARK: - Delete Record
    /// Deletes a specific record from the Core Data managed object context.
    ///
    /// This function searches for a record of the specified `NSManagedObject` type that matches the given attribute name and identifier.
    /// If such a record is found, it is deleted from the managed object context.
    ///
    /// - Parameters:
    ///   - name: The name of the attribute to be used in the search criteria.
    ///   - identifier: The identifier value to be matched against the specified attribute to identify the record.
    ///   - type: The `NSManagedObject` subclass type of the record to be deleted.
    ///
    /// - Returns: A `Bool` indicating whether the deletion was successful. Returns `true` if a matching record was found and deleted,
    ///            or `false` if no matching record was found.
    ///
    /// The function first attempts to fetch the object using the `fetchManagedObject` function with the provided parameters.
    /// If the object is found, it is then deleted from the context using `context.delete()`.
    /// After deleting the object, the context is saved with `self.saveContext()` to persist the changes.
    /// The function returns `true` if a record was found and deleted, or `false` if no record matched the criteria.
    ///
    /// Usage of `@discardableResult` allows the caller to ignore the return value if it's not needed,
    /// while still maintaining the ability to check the result of the deletion if desired.
    @discardableResult public func deleteRecord<T: NSManagedObject>(attribute name: String, by identifier: String, type: T.Type) -> Bool {
        if let object = self.fetchManagedObject(attribute: name, by: identifier, type: type) {
            /// If a matching record is found, delete it
            self.context.delete(object)
            /// Save the context to commit the deletion
            self.saveContext()
            return true
        }
        return false
    }
    // MARK: - Remove CoreData Contents
    /// Removes all records of a specific `NSManagedObject` type from the Core Data managed object context.
    ///
    /// - Parameters:
    ///   - type: The `NSManagedObject` subclass type of the records to be deleted.
    ///   - completion: An optional closure that is called when the operation completes.
    ///   It is called with `nil` if the operation is successful, or an `Error` object if an error occurs.
    ///
    /// This function uses a `NSBatchDeleteRequest` for efficient deletion.
    func removeCoreDataContents<T: NSManagedObject>(type: T.Type, completion: ((Error?) -> Void)? = nil) {
        /// Creates a fetch request object of type NSFetchRequest<T> and initialises it with the `entity name` obtained from the generic type T.
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: T.self))
        /// Set `includesPropertyValues` to` false` to minimize memory usage by fetching only object identifiers
        fetchRequest.includesPropertyValues = false
        /// Create a batch delete request with the fetch request
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
            completion?(nil)
        } catch {
            completion?(error)
        }
    }
}
extension PersistentStorage {
    // MARK: - Delete CoreData PersistentStore
    /// Deletes the Core Data persistent store file from the application support directory.
    ///
    /// - Parameter completion: A closure that is called with a `Result<Void, Error>` indicating the operation's success or failure.
    ///   The closure is called with `.success(())` if the file is successfully removed, or `.failure(Error)` if an error occurs.
    func deleteCoreDataPersistentStore(completion: @escaping (Result<Void, Error>) -> Void) {
        let fileManager = FileManager.default

        /// Retrieve the URL for the application support directory
        guard let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            completion(.failure(PersistentStoreError.directoryNotFound))
            return
        }
        /// Construct the URL for the Core Data SQLite file
        let storeURL = applicationSupportDirectory.appendingPathComponent("VHIRegister.sqlite")

        /// Check if the SQLite file exists
        guard fileManager.fileExists(atPath: storeURL.path) else {
            completion(.failure(PersistentStoreError.fileDoesNotExist))
            return
        }
        /// Attempt to remove the SQLite file
        do {
            try fileManager.removeItem(at: storeURL)
            print("SQLite file removed successfully.")
            completion(.success(()))
        } catch {
            print("Error while removing SQLite file: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    fileprivate enum PersistentStoreError: Error {
        case directoryNotFound
        case fileDoesNotExist

        var localizedDescription: String {
            switch self {
                case .directoryNotFound:
                    return "Application support directory not found."
                case .fileDoesNotExist:
                    return "SQLite file does not exist."
            }
        }
    }
}
