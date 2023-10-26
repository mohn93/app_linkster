library app_linkster;

export 'model/model.dart';
export 'application/application.dart';
import 'dart:io';

import 'package:app_linkster/application/deep_link_creator.dart';
import 'package:app_linkster/model/app_type.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppLinksterLauncher {
  AppLinksterLauncher({
    this.deeplinkCreator = const DeeplinkCreator(),
    Logger? logger,
  }) : logger = logger ?? Logger();

  final DeeplinkCreator deeplinkCreator;
  final Logger logger;

  Future<void> launchThisGuy(String url) async {
    logger.i("Attempting to launch: $url");

    final type = _identifyAppType(url);

    switch (type) {
      case AppType.facebook:
        await _launchFacebook(url);
        break;
      case AppType.twitter:
        await _launchTwitter(url);
        break;
      case AppType.instagram:
        await _launchInstagram(url);
        break;
      case AppType.tiktok:
        await _launchTikTok(url);
        break;
      case AppType.youtube:
        await _launchYoutube(url);
        break;
      case AppType.linkedin:
        await _launchLinkedIn(url);
        break;
      default:
        logger.e("Unknown link type for url: $url");
        throw Exception("Unknown link type");
    }
  }

  Future _launchFacebook(String url) async {
    String parsedUrl = await deeplinkCreator.getDeepLink(
        url: url.replaceFirst('www.', ''),
        type: AppType.facebook,
        idExtractionRegex:
            r'<meta property="al:android:url" content="fb://profile/(\d+)"',
        androidDeepLinkTemplate: 'fb://page/{id}',
        iosDeepLinkTemplate: 'fb://profile/{id}');

    logger.d("Parsed Facebook URL: $parsedUrl");
    await _determineOSAndLaunchUrl(url: url, parsedUrl: parsedUrl);
  }

  Future _launchTikTok(String url) async {
    String parsedUrl = await deeplinkCreator.getDeepLink(
        url: url,
        type: AppType.tiktok,
        idExtractionRegex: r',"authorId":"(\d+)"',
        androidDeepLinkTemplate: 'snssdk1233://user/profile/{id}',
        iosDeepLinkTemplate: 'snssdk1233://user/profile/{id}');
    logger.d("Parsed TikTok URL: $parsedUrl");

    await _determineOSAndLaunchUrl(url: url, parsedUrl: parsedUrl);
  }

  Future _launchTwitter(String url) async {
    String parsedUrl =
        "twitter://user/?screen_name=${Uri.parse(url).pathSegments.lastWhere((item) => item.isNotEmpty)}";
    await _determineOSAndLaunchUrl(url: url, parsedUrl: parsedUrl);
  }

  Future _launchInstagram(String url) async {
    String parsedUrl =
        "instagram://user?username=${Uri.parse(url).pathSegments.lastWhere((item) => item.isNotEmpty)}";
    await _determineOSAndLaunchUrl(url: url, parsedUrl: parsedUrl);
  }

  Future _launchLinkedIn(String url) async {
    String parsedUrl = "linkedin:/${Uri.parse(url).path}";

    await _determineOSAndLaunchUrl(url: url, parsedUrl: parsedUrl);
  }

  Future _launchYoutube(String url) async {
    String parsedUrl =
        "youtube://${"${Uri.parse(url).path}?${Uri.parse(url).query}"}";
    await _determineOSAndLaunchUrl(url: url, parsedUrl: parsedUrl);
  }

  Future _determineOSAndLaunchUrl(
      {required String url, required String parsedUrl}) async {
    String urlToLaunch = (await canLaunchUrlString(parsedUrl) || Platform.isIOS)
        ? parsedUrl
        : url;
    logger.d("Determined URL: $urlToLaunch");

    launchUrlString(urlToLaunch);
  }

  AppType _identifyAppType(String url) {
    const Map<String, AppType> domainToType = {
      "facebook": AppType.facebook,
      "twitter.com": AppType.twitter,
      "instagram.com": AppType.instagram,
      "tiktok.com": AppType.tiktok,
      "youtube.com": AppType.youtube,
      "linkedin.com": AppType.linkedin,
    };

    return domainToType.entries
        .firstWhere((entry) => url.contains(entry.key))
        .value;
  }
}