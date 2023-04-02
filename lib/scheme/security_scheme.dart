/// This class contains all the supported security scheme which will be used for API route authorization
class SecurityScheme {

  /// Bearer token based route authorization
  static Scheme get bearer {
    return Scheme("bearer");
  }

}

/// Authorization scheme
class Scheme {
  final String name;
  Scheme(this.name);
}

