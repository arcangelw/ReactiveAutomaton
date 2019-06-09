//
//  MappingSpec.swift
//  ReactiveAutomaton
//
//  Created by Yasuhiro Inami on 2016-05-07.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import ReactiveSwift
import ReactiveAutomaton
import Quick
import Nimble

/// Tests for `(State, Input) -> State?` mapping.
class MappingSpec: QuickSpec
{
    override func spec()
    {
        typealias Automaton = ReactiveAutomaton.Automaton<AuthState, AuthInput>
        typealias Mapping = Automaton.Mapping

        let (signal, observer) = Signal<AuthInput, Never>.pipe()
        var automaton: Automaton?
        var lastReply: Reply<AuthState, AuthInput>?

        describe("Syntax-sugar Mapping") {

            beforeEach {
                // NOTE: predicate style i.e. `T -> Bool` is also available.
                let canForceLogout: (AuthState) -> Bool = [AuthState.loggingIn, .loggedIn].contains

                let mappings: [Mapping] = [
                    .login    | .loggedOut  => .loggingIn,
                    .loginOK  | .loggingIn  => .loggedIn,
                    .logout   | .loggedIn   => .loggingOut,
                    .logoutOK | .loggingOut => .loggedOut,

                    .forceLogout | canForceLogout => .loggingOut
                ]

                // NOTE: Use `concat` to combine all mappings.
                automaton = Automaton(state: .loggedOut, input: signal, mapping: reduce(mappings))

                _ = automaton?.replies.observeValues { reply in
                    lastReply = reply
                }

                lastReply = nil
            }

            it("`LoggedOut => LoggingIn => LoggedIn => LoggingOut => LoggedOut` succeed") {
                expect(automaton?.state.value) == .loggedOut
                expect(lastReply).to(beNil())

                observer.send(value: .login)

                expect(lastReply?.input) == .login
                expect(lastReply?.fromState) == .loggedOut
                expect(lastReply?.toState) == .loggingIn
                expect(automaton?.state.value) == .loggingIn

                observer.send(value: .loginOK)

                expect(lastReply?.input) == .loginOK
                expect(lastReply?.fromState) == .loggingIn
                expect(lastReply?.toState) == .loggedIn
                expect(automaton?.state.value) == .loggedIn

                observer.send(value: .logout)

                expect(lastReply?.input) == .logout
                expect(lastReply?.fromState) == .loggedIn
                expect(lastReply?.toState) == .loggingOut
                expect(automaton?.state.value) == .loggingOut

                observer.send(value: .logoutOK)

                expect(lastReply?.input) == .logoutOK
                expect(lastReply?.fromState) == .loggingOut
                expect(lastReply?.toState) == .loggedOut
                expect(automaton?.state.value) == .loggedOut
            }

            it("`LoggedOut => LoggingIn ==(ForceLogout)==> LoggingOut => LoggedOut` succeed") {
                expect(automaton?.state.value) == .loggedOut
                expect(lastReply).to(beNil())

                observer.send(value: .login)

                expect(lastReply?.input) == .login
                expect(lastReply?.fromState) == .loggedOut
                expect(lastReply?.toState) == .loggingIn
                expect(automaton?.state.value) == .loggingIn

                observer.send(value: .forceLogout)

                expect(lastReply?.input) == .forceLogout
                expect(lastReply?.fromState) == .loggingIn
                expect(lastReply?.toState) == .loggingOut
                expect(automaton?.state.value) == .loggingOut

                // fails
                observer.send(value: .loginOK)

                expect(lastReply?.input) == .loginOK
                expect(lastReply?.fromState) == .loggingOut
                expect(lastReply?.toState).to(beNil())
                expect(automaton?.state.value) == .loggingOut

                // fails
                observer.send(value: .logout)

                expect(lastReply?.input) == .logout
                expect(lastReply?.fromState) == .loggingOut
                expect(lastReply?.toState).to(beNil())
                expect(automaton?.state.value) == .loggingOut

                observer.send(value: .logoutOK)

                expect(lastReply?.input) == .logoutOK
                expect(lastReply?.fromState) == .loggingOut
                expect(lastReply?.toState) == .loggedOut
                expect(automaton?.state.value) == .loggedOut
            }

        }

        describe("Func-based Mapping") {

            beforeEach {
                let mapping: Mapping = { fromState, input in
                    switch (fromState, input) {
                        case (.loggedOut, .login):
                            return .loggingIn
                        case (.loggingIn, .loginOK):
                            return .loggedIn
                        case (.loggedIn, .logout):
                            return .loggingOut
                        case (.loggingOut, .logoutOK):
                            return .loggedOut

                        // ForceLogout
                        case (.loggingIn, .forceLogout), (.loggedIn, .forceLogout):
                            return .loggingOut

                        default:
                            return nil
                    }
                }

                automaton = Automaton(state: .loggedOut, input: signal, mapping: mapping)

                _ = automaton?.replies.observeValues { reply in
                    lastReply = reply
                }

                lastReply = nil
            }

            it("`LoggedOut => LoggingIn => LoggedIn => LoggingOut => LoggedOut` succeed") {
                expect(automaton?.state.value) == .loggedOut
                expect(lastReply).to(beNil())

                observer.send(value: .login)

                expect(lastReply?.input) == .login
                expect(lastReply?.fromState) == .loggedOut
                expect(lastReply?.toState) == .loggingIn
                expect(automaton?.state.value) == .loggingIn

                observer.send(value: .loginOK)

                expect(lastReply?.input) == .loginOK
                expect(lastReply?.fromState) == .loggingIn
                expect(lastReply?.toState) == .loggedIn
                expect(automaton?.state.value) == .loggedIn

                observer.send(value: .logout)

                expect(lastReply?.input) == .logout
                expect(lastReply?.fromState) == .loggedIn
                expect(lastReply?.toState) == .loggingOut
                expect(automaton?.state.value) == .loggingOut

                observer.send(value: .logoutOK)

                expect(lastReply?.input) == .logoutOK
                expect(lastReply?.fromState) == .loggingOut
                expect(lastReply?.toState) == .loggedOut
                expect(automaton?.state.value) == .loggedOut
            }

            it("`LoggedOut => LoggingIn ==(ForceLogout)==> LoggingOut => LoggedOut` succeed") {
                expect(automaton?.state.value) == .loggedOut
                expect(lastReply).to(beNil())

                observer.send(value: .login)

                expect(lastReply?.input) == .login
                expect(lastReply?.fromState) == .loggedOut
                expect(lastReply?.toState) == .loggingIn
                expect(automaton?.state.value) == .loggingIn

                observer.send(value: .forceLogout)

                expect(lastReply?.input) == .forceLogout
                expect(lastReply?.fromState) == .loggingIn
                expect(lastReply?.toState) == .loggingOut
                expect(automaton?.state.value) == .loggingOut

                // fails
                observer.send(value: .loginOK)

                expect(lastReply?.input) == .loginOK
                expect(lastReply?.fromState) == .loggingOut
                expect(lastReply?.toState).to(beNil())
                expect(automaton?.state.value) == .loggingOut

                // fails
                observer.send(value: .logout)

                expect(lastReply?.input) == .logout
                expect(lastReply?.fromState) == .loggingOut
                expect(lastReply?.toState).to(beNil())
                expect(automaton?.state.value) == .loggingOut

                observer.send(value: .logoutOK)

                expect(lastReply?.input) == .logoutOK
                expect(lastReply?.fromState) == .loggingOut
                expect(lastReply?.toState) == .loggedOut
                expect(automaton?.state.value) == .loggedOut
            }

        }
    }
}
