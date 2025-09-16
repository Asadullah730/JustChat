import 'dart:math';

double cosineSimilarity(List<double> emb1, List<double> emb2) {
  double dot = 0, norm1 = 0, norm2 = 0;
  for (int i = 0; i < emb1.length; i++) {
    dot += emb1[i] * emb2[i];
    norm1 += emb1[i] * emb1[i];
    norm2 += emb2[i] * emb2[i];
  }
  return dot / (sqrt(norm1) * sqrt(norm2));
}
