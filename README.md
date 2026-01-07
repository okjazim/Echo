# Echo (Work In Progress)

Echo is a Flutter application that allows users to browse, search, and download wallpapers. It features a settings page to adjust image resolution and set a download path. Users can also mark wallpapers as favorites and view them in a separate tab.

## Features

- Wallpaper Browsing: Browse through a collection of wallpapers fetched from Unsplash API.
- Search Functionality: Search for specific wallpapers using keywords.
- Image Resolution Settings: Adjust the resolution of the wallpapers (High, Medium, Low).
- Download Path: Set a custom download path for saving wallpapers.
- Favorites: Mark wallpapers as favorites and view them in a separate tab.
- Fullscreen View: View wallpapers in fullscreen mode with zoom and pan functionality.

## Installation

### Prerequisites:

- Flutter SDK installed on your machine.
- Dart SDK installed.
#### Steps:

1. Clone the repository:
```bash
git clone https://github.com/okjazim/Echo.git
```
2. Navigate to the project directory:
```bash
cd Echo
```
3. Install the dependencies:
```bash
flutter pub get
```
4. Run the application:
```bash
flutter run
```

## Usage

1. Browse Wallpapers:

- Open the app and browse through the wallpapers displayed in a grid view.
- Scroll down to load more wallpapers.

2. Search Wallpapers:

- Use the search bar to enter keywords and search for specific wallpapers.

3. Adjust Settings:

- Navigate to the settings page to adjust the image resolution and set a download path.

4. Mark as Favorite:

- Long-press on a wallpaper to mark it as a favorite.
View all favorite wallpapers in the "Favorites" tab.

5. Download Wallpapers:

- Tap the download icon to save the wallpaper to the specified download path.
## Structure

- `main.dart`: Entry point of the application. Initializes the app and sets up the main widget.
- `EchoApp`: The main application widget that sets up the theme and home page.
- `SettingsPage`: A stateful widget for the settings page where users can adjust image resolution and set a download path.
- `WallpaperService`: A service class to fetch wallpapers from the Unsplash API.
- `HomePage`: The main page of the app displaying wallpapers and favorites.
- `FullScreenImage`: A widget to display wallpapers in fullscreen mode with zoom and pan functionality.
- `KeepAlivePage`: A wrapper widget to keep the state of the wallpaper grid alive when switching tabs.

## Dependencies

- `http`: For making HTTP requests to the Unsplash API.
- `cached_network_image`: For caching and displaying network images.
- `shared_preferences`: For storing and retrieving simple persistent data.
- `flutter_staggered_grid_view`: For creating a staggered grid view  of wallpapers.
- `animations`: For creating custom animations.
- `flutter_staggered_animations`: For adding staggered animations to 
  the grid view.
- `permission_handler`: For handling permissions like storage access.
- `file_picker`: For picking directories to set the download path.

## Screenshots

- In Progress

## Important Note

#### Debug Mode Only:
- The Echo Wallpaper App is currently functional only in debug mode. This means that certain features, such as downloading wallpapers and accessing storage, may not work as expected in release mode due to permission restrictions and API limitations.

#### To run the app in debug mode, use the following command:

```bash
flutter run --debug
```
- Ensure that you have the necessary permissions granted in your device settings for the app to function correctly.

## License
This project is licensed under the **MIT License**.
See [`LICENSE`](LICENSE) for details.

## References
- To be added...
