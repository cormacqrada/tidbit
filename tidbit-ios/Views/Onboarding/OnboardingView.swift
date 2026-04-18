import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Learn anything,\nline by line",
            subtitle: "Tidbit transforms any text into personalized learning sessions using spaced repetition.",
            icon: "📚"
        ),
        OnboardingPage(
            title: "Paste a poem,\narticle, or notes",
            subtitle: "We'll detect the content type and generate tidbits — the atomic units of learning.",
            icon: "✍️"
        ),
        OnboardingPage(
            title: "Practice with\nvaried exercises",
            subtitle: "Line prompts, fill-in-the-blank, stanza reconstruction, and more. Each session adapts to you.",
            icon: "🎯"
        ),
        OnboardingPage(
            title: "Build lasting\nmemory",
            subtitle: "Our adaptive engine schedules reviews at optimal intervals, so you never forget what you learn.",
            icon: "🧠"
        )
    ]
    
    var body: some View {
        ZStack {
            DesignSystem.parchment
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(currentPage == index ? DesignSystem.violet : DesignSystem.parchment3)
                    }
                }
                .padding(.bottom, 32)
                
                // Buttons
                HStack(spacing: 16) {
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            isPresented = false
                        }
                        .font(.custom("DM Sans", size: 14))
                        .foregroundColor(DesignSystem.ink3)
                        
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("Get Started") {
                            isPresented = false
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Onboarding Page

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Text(page.icon)
                .font(.system(size: 80))
            
            // Title
            Text(page.title)
                .font(DesignSystem.serif(size: 32))
                .foregroundColor(DesignSystem.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(1.2)
            
            // Subtitle
            Text(page.subtitle)
                .font(.custom("DM Sans", size: 16))
                .foregroundColor(DesignSystem.ink3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - First Launch Handler

struct FirstLaunchHandler: ViewModifier {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .onChange(of: showOnboarding) { _, isShowing in
                if !isShowing {
                    hasCompletedOnboarding = true
                }
            }
    }
}

extension View {
    func handleFirstLaunch() -> some View {
        modifier(FirstLaunchHandler())
    }
}

// MARK: - Sample Poem Helper

enum SamplePoem {
    static let emilyDickinson = """
Because I could not stop for Death —
He kindly stopped for me —
The Carriage held but just Ourselves —
And Immortality.

We slowly drove — He knew no haste
And I had put away
My labor and my leisure too,
For His Civility —

We passed the School, where Children strove
At Recess — in the Ring —
We passed the Fields of Gazing Grain —
We passed the Setting Sun —

Or rather — He passed Us —
The Dews drew quivering and Chill —
For only Gossamer, my Gown —
My Tippet — only Tulle —

We paused before a House that seemed
A Swelling of the Ground —
The Roof was scarcely visible —
The Cornice — in the Ground —

Since then — 'tis Centuries — and yet
Feels shorter than the Day
I first surmised the Horses' Heads
Were toward Eternity —
"""
    
    static let frost = """
Two roads diverged in a yellow wood,
And sorry I could not travel both
And be one traveler, long I stood
And looked down one as far as I could
To where it bent in the undergrowth;

Then took the other, as just as fair,
And having perhaps the better claim,
Because it was grassy and wanted wear;
Though as for that the passing there
Had worn them really about the same,

And both that morning equally lay
In leaves no step had trodden black.
Oh, I kept the first for another day!
Yet knowing how way leads on to way,
I doubted if I should ever come back.

I shall be telling this with a sigh
Somewhere ages and ages hence:
Two roads diverged in a wood, and I—
I took the one less traveled by,
And that has made all the difference.
"""
    
    static let shakespeare = """
Shall I compare thee to a summer's day?
Thou art more lovely and more temperate:
Rough winds do shake the darling buds of May,
And summer's lease hath all too short a date;

Sometime too hot the eye of heaven shines,
And often is his gold complexion dimm'd;
And every fair from fair sometime declines,
By chance or nature's changing course untrimm'd;

But thy eternal summer shall not fade,
Nor lose possession of that fair thou ow'st;
Nor shall death brag thou wander'st in his shade,
When in eternal lines to time thou grow'st:

So long as men can breathe or eyes can see,
So long lives this, and this gives life to thee.
"""
}

// MARK: - Preview

#Preview {
    OnboardingView(isPresented: .constant(true))
}
