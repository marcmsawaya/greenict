//
//  AuthenticationView.swift
//  Greenict
//
//  Created by Unknown Friend on 03/10/2025.
//

import SwiftUI
import FirebaseAuth

// MARK: - Authentication View
struct AuthenticationView: View {
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.green.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Logo Section
                        VStack(spacing: 10) {
                            Image(systemName: "bolt.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.green)
                                .shadow(color: .green.opacity(0.5), radius: 10)
                            
                            Text("Greenict")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Smart Energy Management")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 50)
                        
                        // Toggle between Login and Signup
                        Picker("", selection: $isLoginMode) {
                            Text("Login").tag(true)
                            Text("Sign Up").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // Input Fields
                        VStack(spacing: 15) {
                            if !isLoginMode {
                                CustomTextField(
                                    placeholder: "Full Name",
                                    text: $fullName,
                                    icon: "person.fill"
                                )
                            }
                            
                            CustomTextField(
                                placeholder: "Email",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress
                            )
                            
                            CustomSecureField(
                                placeholder: "Password",
                                text: $password,
                                icon: "lock.fill"
                            )
                            
                            if !isLoginMode {
                                CustomSecureField(
                                    placeholder: "Confirm Password",
                                    text: $confirmPassword,
                                    icon: "lock.fill"
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Button
                        Button(action: handleAuthentication) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text(isLoginMode ? "Login" : "Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        .disabled(isLoading)
                        
                        // Additional Options
                        if isLoginMode {
                            Button("Forgot Password?") {
                                // Handle forgot password
                            }
                            .foregroundColor(.green)
                            .font(.footnote)
                        }
                        
                        // Demo Mode Button
                        Button(action: { authViewModel.signInAsGuest() }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Continue as Demo")
                            }
                            .foregroundColor(.gray)
                            .padding()
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleAuthentication() {
        isLoading = true
        
        if isLoginMode {
            authViewModel.signIn(email: email, password: password) { success, error in
                isLoading = false
                if let error = error {
                    errorMessage = error
                    showError = true
                }
            }
        } else {
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match"
                showError = true
                isLoading = false
                return
            }
            
            authViewModel.signUp(email: email, password: password, fullName: fullName) { success, error in
                isLoading = false
                if let error = error {
                    errorMessage = error
                    showError = true
                }
            }
        }
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Custom Secure Field
struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    @State private var isSecure = true
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
            }
            
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}
