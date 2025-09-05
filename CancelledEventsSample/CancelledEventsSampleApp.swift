//
//  CancelledEventsSampleApp.swift
//  CancelledEventsSample
//
//  Created by Łukasz Śliwiński on 04/09/2025.
//

import ComposableArchitecture
import SwiftUI

@main
struct CancelledEventsSampleApp: App {
    let store = Store(initialState: StableReducer.State()) {
        StableReducer()
    }

    var body: some Scene {
        WindowGroup {
            switch store.destination {
            case .none:
                EmptyView()

            case .destination1:
                if let store = store.scope(state: \.destination?.destination1, action: \.destination.destination1) {
                    DestinationView1(store: store)
                }

            case .destination2:
                if let store = store.scope(state: \.destination?.destination2, action: \.destination.destination2) {
                    DestinationView2(store: store)
                }
            }
        }
    }
}

@Reducer
struct StableReducer {
    @Reducer
    enum Destination {
        case destination1(Destination1)
        case destination2(Destination2)
    }

    @ObservableState
    struct State {
        @Presents var destination: Destination.State? = .destination1(.init())
    }

    enum Action {
        case changeDestination
        case doSomething
        case destination(PresentationAction<Destination.Action>)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .changeDestination:
                print("will change destination")
                state.destination = .destination2(.init())
                print("did change destination")
                return .none
            case .doSomething:
                print("start running something")
                return .run { send in
                    Task {
                        try await Task.sleep(for: .seconds(5))
                        print("ask to change destination")
                        await send(.changeDestination)
                    }

                    // Simulate long running task
                    do {
                        try await Task.sleep(for: .seconds(10))
                        print("✅ finished successfully")
                    } catch {
                        print("❌ finished with error: \(error)")
                    }

                    // Workaround to opt-out from the cancellation
                    Task {
                        do {
                            try await Task.sleep(for: .seconds(10))
                            print("✅ opted-out Task finished successfully")
                        } catch {
                            print("❌ opted-out Task finished with error: \(error)")
                        }
                    }
                }
            case .destination(.presented(.destination1(.task))):
                return .none
            case .destination(.presented(.destination1(.output))):
                return .send(.doSomething)
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination.body
        }
    }
}

struct DestinationView1: View {
    let store: StoreOf<Destination1>

    var body: some View {
        Text("Destination 1")
            .task {
                await store.send(.task).finish()
            }
    }
}

@Reducer
struct Destination1 {
    @ObservableState
    struct State {}

    enum Action {
        case task
        case output
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .task:
                .send(.output)
            case .output:
                .none
            }
        }
    }
}

struct DestinationView2: View {
    let store: StoreOf<Destination2>

    var body: some View {
        Text("Destination 2")
    }
}

@Reducer
struct Destination2 {
    @ObservableState
    struct State {}

    enum Action {}

    var body: some ReducerOf<Self> {
        Reduce { _, _ in
            return .none
        }
    }
}
