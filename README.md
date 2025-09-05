# TCA Cancelled Effects Investigation

This project demonstrates and investigates an issue with The Composable Architecture (TCA) where effects appear to be cancelled unexpectedly when destination states change within a stable reducer.

## Issue Description

## UPDATE - Clarification: Expected TCA behavior

Per guidance from the TCA maintainers, the behavior demonstrated here is **expected** in The Composable Architecture, even if it may feel unintuitive at first.

In short, when a child feature is dismissed, TCA cancels effects that originated from that child (and any effects they spawned), even if a parent reducer is the one returning the effect.

### Expected Behavior
When a reducer remains in place and only its internal destination states change (e.g., from `destination1` to `destination2`), effects running in the parent reducer should **NOT** be cancelled.

### Observed Behavior
Effects are being cancelled when destination states change, even though the parent reducer itself is not being dismissed or removed.

## The Cancellation Scenario

The issue occurs in this sequence:

1. **Destination1** is presented and sends an action
2. **Parent reducer** handles the action and starts a long-running effect∆
3. **During the effect execution**, the destination state changes from `destination1` to `destination2`
4. **The long-running effect gets cancelled** unexpectedly

### Debugging Information
- Cancellation appears to happen at: [`ComposableArchitecture/Core.swift#L131`](https://github.com/pointfreeco/swift-composable-architecture/blob/d772c216bb83cbb83d6ea0d6309256b1ba007412/Sources/ComposableArchitecture/Core.swift#L131)
- This suggests the Task is being cancelled by TCA's internal effect management

## Workaround

If you need effects to not observe cancellation, you can wrap them in a non-cancellable Task:

```swift
return .run { _ in 
    await Task { 
        // async work in here will not observe cancellation
        await doSomething() 
    }
    .value
}
```

## How to Reproduce

1. Run the sample app
2. The app automatically starts with `destination1` presented
3. `Destination1` triggers a `.task` action which sends `.doSomething` to the parent
4. The parent starts a long-running effect (10 seconds)
5. After 5 seconds, the effect triggers a destination change to `destination2`
6. **Expected**: The remaining 5 seconds of the effect should complete
7. **Observed**: The effect gets cancelled when destination changes

## Console Output

```
start running something
ask to change destination
will change destination
did change destination
❌ finished with error: CancellationError()
```

## TCA Version

This project uses the latest version of TCA 1.22.2.