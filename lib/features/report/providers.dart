import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/report_repository.dart';
import 'models/report.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) => ReportRepository());

final myReportsProvider = StreamProvider<List<ReportDoc>>((ref) {
  return ref.watch(reportRepositoryProvider).myReports();
});

final recentReportsProvider = StreamProvider<List<ReportDoc>>((ref) {
  return ref.watch(reportRepositoryProvider).recentReports(limit: 50);
});

class CreateReportState {
  final bool loading;
  final String? error;
  final String? reportId;
  final File? pickedFile;
  const CreateReportState({this.loading = false, this.error, this.reportId, this.pickedFile});
  CreateReportState copyWith({bool? loading, String? error, String? reportId, File? pickedFile}) =>
      CreateReportState(
        loading: loading ?? this.loading,
        error: error,
        reportId: reportId,
        pickedFile: pickedFile ?? this.pickedFile,
      );
}

class CreateReportController extends StateNotifier<CreateReportState> {
  final ReportRepository repo;
  CreateReportController(this.repo) : super(const CreateReportState());

  Future<void> pickImage() async {
    final x = await repo.pickImage();
    if (x == null) return;
    state = state.copyWith(pickedFile: File(x.path));
  }

  Future<void> submit({required String category, String? description, GeoPoint? location}) async {
    try {
      state = state.copyWith(loading: true, error: null, reportId: null);
      final reportId = await repo.createReport(category: category, description: description, location: location);
      String? url;
      if (state.pickedFile != null) {
        url = await repo.uploadImage(state.pickedFile!, reportId: reportId);
        await FirebaseFirestore.instance.collection('reports').doc(reportId).update({'imageUrl': url});
      }
      state = state.copyWith(loading: false, reportId: reportId);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final createReportControllerProvider = StateNotifierProvider<CreateReportController, CreateReportState>((ref) {
  return CreateReportController(ref.watch(reportRepositoryProvider));
});