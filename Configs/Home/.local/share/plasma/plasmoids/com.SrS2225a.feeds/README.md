# Plasma News Widget

## Overview
The Plasma News Widget is a lightweight plasmoid that fetches and displays news articles from the internet using RSS feeds. While designed primarily for news, it supports any valid RSS feed.

## Features
- Fetches news articles from specified RSS feeds.
- View the full article by clicking the Read More button
- Easily switch between news sources and navigate between articles

## Project Structure
```
plasma-news-widget
├── contents
│   ├── config
│   │   ├── config.qml        # Configuration settings  
│   │   ├── main.xml          # Main configuration file  
│   ├── ui
│   │   ├── configGeneral.qml # General settings UI  
│   │   ├── main.qml          # Main UI layout  
│   ├── utils
│   │   ├── newsFetcher.js    # Handles fetching and processing RSS feeds  
├── LICENSE                   # License information  
├── metadata.json             # Widget metadata  
└── README.md                 # Project documentation  
```

## Setup Instructions
1. **Clone the repository:**
   ```
   git clone https://github.com/yourusername/plasma-news-widget.git
   cd plasma-news-widget
   ```
   Requires:  Plasma >= 6.0

2. **Testing:**
   Refer to: https://develop.kde.org/docs/plasma/widget/testing/

3. **Installing:**
   You can install it easily from the KDE Widgets store, or alternative you can execute `kpackagetool6 -i .` in the root directory of the applet.

## Contributing
Contributions are welcome! Please feel free to submit a pull request or open an issue for any suggestions or improvements.

## License
This project is licensed under the GNU General Public License version 2. See LICENSE for details
