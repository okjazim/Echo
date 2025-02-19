import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String initialResolution = prefs.getString('image_resolution') ?? 'Low';
  runApp(EchoApp(initialResolution: initialResolution));
}

class EchoApp extends StatelessWidget {
  final String initialResolution;

  EchoApp({required this.initialResolution});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF868cb3),
        fontFamily: 'Roboto',
      ),
      home: HomePage(initialResolution: initialResolution),
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedResolution = 'Low';
  String downloadPath = '';

  @override
  void initState() {
    super.initState();
    _loadResolution();
    _loadDownloadPath();
  }

  void _loadResolution() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedResolution = prefs.getString('image_resolution') ?? 'Low';
    });
  }

  void _loadDownloadPath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      downloadPath = prefs.getString('download_path') ?? '';
    });
  }

  void updateResolution(String value) {
    setState(() {
      selectedResolution = value;
    });
  }

  void saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('image_resolution', selectedResolution);
    await prefs.setString('download_path', downloadPath);
    Navigator.pop(context, {
      'resolution': selectedResolution,
      'downloadPath': downloadPath,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved')),
    );
  }

  Future<void> _pickDownloadPath() async {
    var status = await Permission.storage.status;

    if (status.isDenied) {
      status = await Permission.storage.request();
      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission is required to set download path'),
            ),
          );
        }
        return;
      }
    }

    if (status.isGranted) {
      String? result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        setState(() {
          downloadPath = result;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to set download path'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF868cb3),
        elevation: 4,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 3,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ListTile(
                title: const Text('Image Quality'),
                subtitle: const Text('Adjust image resolution'),
                trailing: DropdownButton(
                  value: selectedResolution,
                  items: ['High', 'Medium', 'Low']
                      .map((String value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      updateResolution(newValue);
                    }
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: Text('Selected Resolution: $selectedResolution'),
                subtitle: Text(_getResolutionPercentage()),
              ),
              const Divider(),
              ListTile(
                title: const Text('Download Path'),
                subtitle: Text(downloadPath.isEmpty ? 'Not set' : downloadPath),
                trailing: IconButton(
                  icon: const Icon(Icons.folder),
                  onPressed: _pickDownloadPath,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveSettings,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getResolutionPercentage() {
    switch (selectedResolution) {
      case 'High':
        return '100%';
      case 'Medium':
        return '75%';
      case 'Low':
        return '50%';
      default:
        return '100%';
    }
  }
}

class WallpaperService {
  static const String apiUrl = 'https://api.unsplash.com/search/photos';
  static const String accessKey = 'WkLujxykziPSvuEYSLvgpFTZDDIuRkKL1YSTkrBEIhY';

  Future<List<Map<String, String>>> getWallpapers(String query, int page, String resolution) async {
    String size;
    switch (resolution) {
      case 'High':
        size = 'full';
        break;
      case 'Medium':
        size = 'regular';
        break;
      case 'Low':
        size = 'small';
        break;
      default:
        size = 'full';
    }

    final response = await http.get(
      Uri.parse('$apiUrl?client_id=$accessKey&query=$query&per_page=30&page=$page'),
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> results = data['results'];
      return results.map((wallpaper) => {
        'id': wallpaper['id'].toString(),
        'url': wallpaper['urls'][size].toString(),
      }).toList();
    } else {
      throw Exception('Failed to load wallpapers: ${response.statusCode}');
    }
  }
}

class HomePage extends StatefulWidget {
  final String initialResolution;

  HomePage({required this.initialResolution});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Map<String, String>> wallpapers = [];
  Set<String> favouriteImageIds = {};
  bool isLoading = true;
  bool hasMore = true;
  int page = 1;
  ScrollController _scrollController = ScrollController();
  TextEditingController _searchController = TextEditingController();
  TabController? _tabController;
  String selectedResolution = 'Low';
  String downloadPath = '';
  List<Map<String, String>> favouriteWallpapers = [];
  ScrollController _favouritesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    selectedResolution = widget.initialResolution;
    _loadDownloadPath();
    _loadFavourites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWallpapers('1080 nature wallpaper');
    });
    _scrollController.addListener(_scrollListener);
  }

  void _loadDownloadPath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      downloadPath = prefs.getString('download_path') ?? '';
    });
  }

  void _loadFavourites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      favouriteImageIds = Set<String>.from(prefs.getStringList('favouriteIds') ?? []);
      final favouriteData = prefs.getString('favouriteWallpapers');
      if (favouriteData != null) {
        final List<dynamic> decoded = json.decode(favouriteData);
        favouriteWallpapers = decoded.map((item) => Map<String, String>.from(item)).toList();
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadWallpapers(_searchController.text.isEmpty ? '1080 nature wallpaper' : _searchController.text);
    }
  }

  void _loadWallpapers(String query) async {
    if (!hasMore) return;
    try {
      final fetchedWallpapers = await WallpaperService().getWallpapers(query, page, selectedResolution);
      setState(() {
        wallpapers.addAll(fetchedWallpapers);
        isLoading = false;
        if (fetchedWallpapers.isEmpty) {
          hasMore = false;
        } else {
          page++;
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load wallpapers: $e')),
      );
    }
  }

  void _searchWallpapers(String query) {
    setState(() {
      wallpapers.clear();
      page = 1;
      hasMore = true;
      isLoading = true;
    });
    _loadWallpapers(query.isEmpty ? '1080 nature wallpaper' : query);
  }

  void _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
    if (result != null && result is Map<String, String>) {
      setState(() {
        selectedResolution = result['resolution']!;
        downloadPath = result['downloadPath']!;
      });
      _searchWallpapers(_searchController.text);
    }
  }

  void _openFullScreen(BuildContext context, String imageUrl, String imageId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: FullScreenImage(
              imageUrl: imageUrl,
              imageId: imageId,
              isFavorite: favouriteImageIds.contains(imageId),
              onFavoriteToggle: _toggleFavorite,
              downloadPath: downloadPath,
            ),
          );
        },
      ),
    );
  }

  void _toggleFavorite(String imageId) async {
    setState(() {
      if (favouriteImageIds.contains(imageId)) {
        favouriteImageIds.remove(imageId);
        favouriteWallpapers.removeWhere((wallpaper) => wallpaper['id'] == imageId);
      } else {
        favouriteImageIds.add(imageId);
        final wallpaper = wallpapers.firstWhere((w) => w['id'] == imageId);
        favouriteWallpapers.add(wallpaper);
      }
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favouriteIds', favouriteImageIds.toList());
    await prefs.setString('favouriteWallpapers', json.encode(favouriteWallpapers));
  }

  Future<void> _downloadImage(String imageUrl) async {
    if (downloadPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a download path in settings.')),
      );
      return;
    }

    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required to download images.')),
        );
        return;
      }

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '$downloadPath/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image downloaded to $filePath')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download image: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF555555),
      appBar: AppBar(
        backgroundColor: const Color(0xFF868cb3),
        elevation: 4,
        title: const Text(
          'Echo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 3,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Wallpapers'),
            Tab(text: 'Favourites'),
          ],
          indicatorWeight: 3,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.label,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 24),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: _tabController!.animation!.drive(IntTween(begin: 0, end: 1)),
            builder: (context, currentIndex, child) {
              return AnimatedOpacity(
                opacity: currentIndex == 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: currentIndex == 0 ? 56 : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: _searchController,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Search...',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                            onSubmitted: (query) {
                              _searchWallpapers(query);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                KeepAlivePage(
                  child: _buildWallpaperGrid(wallpapers, scrollController: _scrollController),
                ),
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildWallpaperGrid(
                        favouriteWallpapers,
                        scrollController: _favouritesScrollController,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWallpaperGrid(
    List<Map<String, String>> wallpapers, {
    ScrollController? scrollController,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AnimationLimiter(
        child: MasonryGridView.count(
          controller: scrollController ?? _scrollController,
          crossAxisCount: 2,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16.0),
          itemCount: wallpapers.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == wallpapers.length && isLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            final wallpaper = wallpapers[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                scale: 0.5,
                child: FadeInAnimation(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _openFullScreen(context, wallpaper['url']!, wallpaper['id']!),
                      onLongPress: () => _toggleFavorite(wallpaper['id']!),
                      child: Hero(
                        tag: wallpaper['url']!,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: wallpaper['url']!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFF555555),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        favouriteImageIds.contains(wallpaper['id'])
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _toggleFavorite(wallpaper['id']!),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.download, color: Color(0xFF868cb3)),
                                      onPressed: () => _downloadImage(wallpaper['url']!),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class FullScreenImage extends StatefulWidget {
  final String imageUrl;
  final String imageId;
  final bool isFavorite;
  final Function(String) onFavoriteToggle;
  final String downloadPath;

  const FullScreenImage({
    required this.imageUrl,
    required this.imageId,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.downloadPath,
  });

  @override
  _FullScreenImageState createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isFavorite;
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    widget.onFavoriteToggle(widget.imageId);
  }

  Future<void> _downloadImage() async {
    if (widget.downloadPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a download path in settings.')),
      );
      return;
    }

    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required to download images.')),
        );
        return;
      }

      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '${widget.downloadPath}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image downloaded to $filePath')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download image: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Hero(
                tag: widget.imageUrl,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.download, color: Color(0xFF868cb3)),
                    onPressed: _downloadImage,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _KeepAlivePageState createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
