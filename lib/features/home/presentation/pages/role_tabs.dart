import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/jobs/presentation/pages/jobs_page.dart';
import 'package:home_service_app/features/profile/presentation/pages/profile_list_page.dart';
import 'package:home_service_app/features/search_ai/presentation/pages/client_requests_page.dart';
import 'package:home_service_app/features/search_ai/presentation/pages/search_ai_page.dart';

class RoleHomePage extends StatelessWidget {
  const RoleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isProvider =
        context.watch<AuthCubit>().state.user?.isProvider ?? false;
    return isProvider ? const JobsPage() : const SearchAiPage();
  }
}

class RoleSecondPage extends StatelessWidget {
  const RoleSecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isProvider =
        context.watch<AuthCubit>().state.user?.isProvider ?? false;
    if (isProvider) {
      return const ProfileListPage();
    }
    return const ClientRequestsPage();
  }
}
