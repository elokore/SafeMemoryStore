# SafeMemoryStore
A simple wrapper for MemoryStoreService using Promises.

Functions of MemoryStoreService can yield for unpredictable amounts of time and can outright fail
if Roblox starts encountering outages or slowdowns. These problems require that we take measures to prevent
our game from breaking when function calls fail or it yields longer than normal. Usually this is done by wrapping
everything in pcalls which gets messy quickly.

SafeMemoryStore fixes these problems using Promises to give us error-handling, automatic retries and to remove yielding.