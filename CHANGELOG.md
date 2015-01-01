## 0.0.2

* Calling `#revise` on new document simply creates it (`:revise` callbacks are not triggered).
* Added `#revise!` method raising Mongoid exceptions.
* Added tests for conflicting updates.
* Added thread-safe version check and a loop to resolve version discrepancies in case of failure.

## 0.0.1

Initial version