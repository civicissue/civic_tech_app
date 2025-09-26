import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
  final GeoPoint? location;
  final String? address;
  const CreateReportState({this.loading = false, this.error, this.reportId, this.pickedFile, this.location, this.address});
  CreateReportState copyWith({bool? loading, String? error, String? reportId, File? pickedFile, GeoPoint? location, String? address}) =>
      CreateReportState(
        loading: loading ?? this.loading,
        error: error,
        reportId: reportId,
        pickedFile: pickedFile ?? this.pickedFile,
        location: location ?? this.location,
        address: address ?? this.address,
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

  Future<void> setLocation(GeoPoint loc, String address) async {
    state = state.copyWith(location: loc, address: address);
  }

  Future<void> submit({required String category, required String description}) async {
    try {
      if (state.pickedFile == null) {
        state = state.copyWith(error: 'Please add a photo');
        return;
      }
      if (state.location == null || state.address == null) {
        state = state.copyWith(error: 'Please select the exact location');
        return;
      }
      state = state.copyWith(loading: true, error: null, reportId: null);
      final tempId = const Uuid().v4();
      final url = await repo.uploadImage(state.pickedFile!, reportId: tempId) ?? '';
      final reportId = await repo.createReport(
        category: category,
        description: description,
        location: state.location!,
        address: state.address!,
        imageUrl: url,
      );
      state = state.copyWith(loading: false, reportId: reportId);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final createReportControllerProvider = StateNotifierProvider<CreateReportController, CreateReportState>((ref) {
  return CreateReportController(ref.watch(reportRepositoryProvider));
});