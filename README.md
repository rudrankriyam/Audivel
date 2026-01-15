# Audivel
[![Star History Chart](https://api.star-history.com/svg?repos=rudrankriyam/Audivel&type=Date)](https://star-history.com/#rudrankriyam/Audivel&Date)


Audivel is a macOS, iOS, and visionOS app that generates audio content from PDF using Play.ai's PlayNote API. It provides a simple interface to convert PDF into natural-sounding podcast, narrative, children's story, or debate with various voice options.

## Features

- Generate audio content using Play.ai's AI voices
- Support for multiple synthesis styles (podcast format)
- Real-time status updates during generation
- Cross-platform support (macOS, iOS, visionOS)

## Prerequisites

Before you begin, ensure you have:

- Xcode 15.0 or later
- macOS 14.0 or later for development
- A Play.ai Developer Account
- Play.ai API Key and User ID

## Setup

1. Clone the repository:

```bash
git clone https://github.com/rudrankriyam/Audivel.git
cd Audivel
```

2. Create a `.env` file in the project root:

```bash
touch .env
```

3. Add your Play.ht credentials to the `.env` file:

```bash
PLAY_HT_API_KEY=<your-play-ht-api-key>
PLAY_HT_USER_ID=<your-play-ht-user-id>
```

To obtain your API credentials:

1. Visit [Play.ai Developer Portal](https://play.ai/developers)
2. Sign in or create an account
3. Navigate to the API section
4. Copy your API Key and User ID
5. Paste them into the `.env` file

## Usage

1. Open the Xcode project:

```bash
open Audivel.xcodeproj
```

2. Build and run the project (⌘R)

3. Enter a source URL containing the PDF you want to convert to speech

4. Click "Generate PlayNote" to start the conversion

## Requirements

- iOS 16.0+
- macOS 14.0+
- visionOS 1.0+
- Xcode 15.0+
- Swift 5.9+

## Dependencies

- [SakuraKit](https://github.com/rryam/SakuraKit.git) - Swift SDK for Prototyping AI Speech Generation
- [Orb](https://github.com/metasidd/Orb) - A mesmerizing orb, fully designed in SwiftUI. The project would not have been so pretty without it. 🙏

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Rudrank Riyam [@rudrankriyam](https://x.com/rudrankriyam)

## Note

Make sure to keep your API credentials secure and never commit the `.env` file to version control. The `.gitignore` file is already configured to exclude it.
