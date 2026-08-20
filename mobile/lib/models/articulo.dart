class Articulo {
  final String id;
  final String titulo;
  final String descripcion;
  final double precio;

  Articulo({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.precio,
  });

  factory Articulo.fromJson(Map<String, dynamic> json) {
    return Articulo(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: (json['precio'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio,
    };
  }
}