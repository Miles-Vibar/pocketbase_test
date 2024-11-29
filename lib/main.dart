import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class Pb {
  final pb = PocketBase('http://26.52.10.65:8080');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Pb().pb.authStore.isValid ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginPage(),
      },
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();

  final password = TextEditingController();

  final pb = Pb();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: username,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(24),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                label: const Text('Username'),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(24),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                label: const Text('Password'),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: !pb.pb.authStore.isValid
                        ? () async {
                            await pb.pb
                                .collection('users')
                                .authWithPassword(username.text, password.text);

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  pb.pb.authStore.isValid
                                      ? 'Logged In Successfully'
                                      : 'Invalid Credentials',
                                ),
                              ),
                            );

                            if (pb.pb.authStore.isValid) {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => HomePage(pb: pb)));
                            }

                            setState(() {});
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('LOGIN'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class Post extends Equatable {
  final String? id;
  final String? post;
  final String? dateCreated;

  const Post({
    this.id,
    this.post,
    this.dateCreated,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'],
        post: json['text'],
        dateCreated: json['created'],
      );

  Map<String, dynamic> toMap() => {
        'text': post,
      };

  @override
  // TODO: implement props
  List<Object?> get props => [
        id,
      ];
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.pb,
  });

  final Pb pb;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Post> posts = [];

  final postController = TextEditingController();

  int _index = 0;
  bool _ascending = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _init();
    widget.pb.pb.collection('posts').subscribe("*", (e) async {
      posts = (await widget.pb.pb.collection('posts').getFullList())
          .map((value) => Post.fromJson(value.data))
          .toList();
      setState(() {});
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    widget.pb.pb.collection('posts').unsubscribe();
  }

  _init() async {
    posts = (await widget.pb.pb.collection('posts').getFullList())
        .map((value) => Post.fromJson(value.data))
        .toList();
    setState(() {});
  }

  _sort() {
    if (!_ascending) {
      posts.sort(
        (a, b) => DateTime.parse(a.dateCreated!).compareTo(
          DateTime.parse(b.dateCreated!),
        ),
      );
    } else {
      posts.sort(
        (a, b) => DateTime.parse(b.dateCreated!).compareTo(
          DateTime.parse(a.dateCreated!),
        ),
      );
    }
  }

  Future<void> _addPost(String value) async {
    final post = Post(post: value);

    await widget.pb.pb.collection('posts').create(body: post.toMap());
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketBase'),
        actions: [
          if (widget.pb.pb.authStore.isValid)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    widget.pb.pb.authStore.clear();
                    setState(() {});
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          const SizedBox(
            width: 16,
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: PaginatedDataTable(
                  sortAscending: _ascending,
                  sortColumnIndex: _index,
                  rowsPerPage: 8,
                  header: Row(
                    children: [
                      const Expanded(child: Text('Posts')),
                      FilledButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text('Enter New Post'),
                            content: TextField(
                              controller: postController,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  postController.clear();
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _addPost(postController.text);
                                  Navigator.pop(context);
                                  postController.clear();
                                },
                                child: const Text('Post'),
                              ),
                            ],
                          ),
                        ),
                        icon: const Icon(
                          Icons.add,
                        ), label: const Text("Add Post"),
                      ),
                    ],
                  ),
                  columns: [
                    const DataColumn(
                      label: Text('#'),
                    ),
                    const DataColumn(
                      label: Text('Text'),
                    ),
                    DataColumn(
                      label: const Text('Date Created'),
                      onSort: (index, asc) {
                        _ascending = asc;
                        _index = index;
                        _sort();
                        setState(() {});
                      },
                    ),
                  ],
                  source: Data(posts: posts),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Data extends DataTableSource {
  Data({required this.posts});

  final List<Post> posts;

  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow
    return DataRow(
      cells: [
        DataCell(Text(posts[index].id!)),
        DataCell(Text(posts[index].post!)),
        DataCell(
          Text(
            DateFormat(' EEEE, y MMMM d - hh:mm a').format(
              DateTime.parse(posts[index].dateCreated!),
            ),
          ),
        ),
      ],
    );
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => false;

  @override
  // TODO: implement rowCount
  int get rowCount => posts.length;

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => 0;
}