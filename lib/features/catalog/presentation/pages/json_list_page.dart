import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JsonListPage extends StatelessWidget {
  const JsonListPage({
    super.key,
    required this.title,
    this.subtitleBuilder,
    this.trailingBuilder,
    this.where,
  });

  final String title;
  final String Function(Map<String, dynamic> item)? subtitleBuilder;
  final Widget Function(Map<String, dynamic> item)? trailingBuilder;
  final bool Function(Map<String, dynamic> item)? where;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.read<JsonListCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<JsonListCubit, ListLoadState>(
        builder: (context, state) {
          if (state is ListLoadLoading || state is ListLoadInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ListLoadFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.read<JsonListCubit>().load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final raw = (state as ListLoadLoaded).items;
          final items = where == null
              ? raw
              : raw.where(where!).toList(growable: false);
          if (items.isEmpty) {
            return const Center(child: Text('Nothing here yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = items[i];
              final subtitle = subtitleBuilder?.call(item);
              return ListTile(
                title: Text(
                  _primaryLabel(item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: subtitle != null ? Text(subtitle) : null,
                trailing: trailingBuilder?.call(item),
              );
            },
          );
        },
      ),
    );
  }

  String _primaryLabel(Map<String, dynamic> item) {
    if (item['name'] != null) return item['name'].toString();
    if (item['fullName'] != null) return item['fullName'].toString();
    if (item['email'] != null) return item['email'].toString();
    if (item['id'] != null) return item['id'].toString();
    return item.toString();
  }
}

/// Branded empty wrapper for list screens that need a [FloatingActionButton].
class JsonListPageWithFab extends StatelessWidget {
  const JsonListPageWithFab({
    super.key,
    required this.title,
    required this.fab,
    this.subtitleBuilder,
    this.trailingBuilder,
  });

  final String title;
  final Widget fab;
  final String Function(Map<String, dynamic> item)? subtitleBuilder;
  final Widget Function(Map<String, dynamic> item)? trailingBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.read<JsonListCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: fab,
      body: BlocBuilder<JsonListCubit, ListLoadState>(
        builder: (context, state) {
          if (state is ListLoadLoading || state is ListLoadInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ListLoadFailure) {
            return Center(child: Text(state.message));
          }
          final items = (state as ListLoadLoaded).items;
          if (items.isEmpty) {
            return const Center(child: Text('Nothing here yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = items[i];
              final subtitle = subtitleBuilder?.call(item);
              return ListTile(
                title: Text(
                  item['name']?.toString() ??
                      item['fullName']?.toString() ??
                      item['id'].toString(),
                ),
                subtitle: subtitle != null ? Text(subtitle) : null,
                trailing: trailingBuilder?.call(item),
              );
            },
          );
        },
      ),
    );
  }
}
