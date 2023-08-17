# SafeMemoryStore
A simple wrapper for MemoryStoreService using Promises.

Functions of MemoryStoreService can yield for unpredictable amounts of time and can outright fail
if Roblox starts encountering outages or slowdowns. These problems mandate that we take measures to prevent
our game from breaking when function calls fail or yield longer than normal. Usually this is done by wrapping
everything in pcalls but this gets messy quickly.

SafeMemoryStore fixes these problems using Promises to give us error-handling, automatic retries and erradicating yielding.