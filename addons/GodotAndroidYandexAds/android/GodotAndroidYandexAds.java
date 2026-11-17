package com.darkmoonight.godotandroidyandexads;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Insets;
import android.os.Build;
import android.util.ArraySet;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.WindowInsets;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.yandex.mobile.ads.appopenad.AppOpenAd;
import com.yandex.mobile.ads.appopenad.AppOpenAdEventListener;
import com.yandex.mobile.ads.appopenad.AppOpenAdLoadListener;
import com.yandex.mobile.ads.appopenad.AppOpenAdLoader;
import com.yandex.mobile.ads.banner.BannerAdEventListener;
import com.yandex.mobile.ads.banner.BannerAdSize;
import com.yandex.mobile.ads.banner.BannerAdView;
import com.yandex.mobile.ads.common.AdError;
import com.yandex.mobile.ads.common.AdRequest;
import com.yandex.mobile.ads.common.AdRequestError;
import com.yandex.mobile.ads.common.ImpressionData;
import com.yandex.mobile.ads.common.YandexAds;
import com.yandex.mobile.ads.interstitial.InterstitialAd;
import com.yandex.mobile.ads.interstitial.InterstitialAdEventListener;
import com.yandex.mobile.ads.interstitial.InterstitialAdLoadListener;
import com.yandex.mobile.ads.interstitial.InterstitialAdLoader;
import com.yandex.mobile.ads.rewarded.Reward;
import com.yandex.mobile.ads.rewarded.RewardedAd;
import com.yandex.mobile.ads.rewarded.RewardedAdEventListener;
import com.yandex.mobile.ads.rewarded.RewardedAdLoadListener;
import com.yandex.mobile.ads.rewarded.RewardedAdLoader;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Set;

import io.appmetrica.analytics.AppMetrica;
import io.appmetrica.analytics.AppMetricaConfig;

public class GodotAndroidYandexAds extends GodotPlugin {
	private static final String YANDEX_MOBILE_ADS_TAG = "YandexMobileAds";
	private final Activity activity;
	@Nullable
	private BannerAdView bannerAdView = null;
	@Nullable
	private RewardedAd rewardedAd = null;
	@Nullable
	private InterstitialAd interstitialAd = null;
	@Nullable
	private AppOpenAd appOpenAd = null;
	private FrameLayout layout = null;
	private FrameLayout.LayoutParams adParams = null;
	private volatile int bannerWidthPixels = 0;
	private volatile int bannerHeightPixels = 0;
	private int bannerWidthDp = 0;

	public GodotAndroidYandexAds(Godot godot) {
		super(godot);
		this.activity = getActivity();
	}

	@NonNull
	@Override
	public String getPluginName() {
		return "GodotAndroidYandexAds";
	}

	@NonNull
	@Override
	public Set getPluginSignals() {
		Set signals = new ArraySet<>();
		addBannerSignals(signals);
		addRewardedSignals(signals);
		addInterstitialSignals(signals);
		addAppOpenSignals(signals);
		return signals;
	}

	private void addBannerSignals(Set signals) {
		signals.add(new SignalInfo("_on_banner_loaded"));
		signals.add(new SignalInfo("_on_banner_failed_to_load", Integer.class));
		signals.add(new SignalInfo("_on_banner_clicked"));
		signals.add(new SignalInfo("_on_banner_left_application"));
		signals.add(new SignalInfo("_on_returned_to_application_after_banner"));
	}

	private void addRewardedSignals(Set signals) {
		signals.add(new SignalInfo("_on_rewarded_video_ad_loaded"));
		signals.add(new SignalInfo("_on_rewarded_video_ad_failed_to_load", Integer.class));
		signals.add(new SignalInfo("_on_rewarded_video_ad_show"));
		signals.add(new SignalInfo("_on_rewarded_video_ad_failed_to_show", String.class));
		signals.add(new SignalInfo("_on_rewarded_video_ad_dismissed"));
		signals.add(new SignalInfo("_on_rewarded_video_ad_clicked"));
		signals.add(new SignalInfo("_on_rewarded", String.class, Integer.class));
	}

	private void addInterstitialSignals(Set signals) {
		signals.add(new SignalInfo("_on_interstitial_loaded"));
		signals.add(new SignalInfo("_on_interstitial_failed_to_load", Integer.class));
		signals.add(new SignalInfo("_on_interstitial_ad_show"));
		signals.add(new SignalInfo("_on_interstitial_failed_to_show", String.class));
		signals.add(new SignalInfo("_on_interstitial_ad_dismissed"));
		signals.add(new SignalInfo("_on_interstitial_clicked"));
	}

	private void addAppOpenSignals(Set signals) {
		signals.add(new SignalInfo("_on_app_open_ad_loaded"));
		signals.add(new SignalInfo("_on_app_open_ad_failed_to_load", Integer.class));
		signals.add(new SignalInfo("_on_app_open_ad_show"));
		signals.add(new SignalInfo("_on_app_open_ad_failed_to_show", String.class));
		signals.add(new SignalInfo("_on_app_open_ad_dismissed"));
		signals.add(new SignalInfo("_on_app_open_ad_clicked"));
	}

	@UsedByGodot
	public void init(@NonNull final String apiKey) {
		if (!apiKey.isEmpty()) {
			AppMetricaConfig config = AppMetricaConfig.newConfigBuilder(apiKey).build();
			AppMetrica.activate(activity.getApplicationContext(), config);
			AppMetrica.enableActivityAutoTracking(activity.getApplication());
		}
		YandexAds.initialize(activity, () -> Log.d(YANDEX_MOBILE_ADS_TAG, "SDK initialized"));
	}

	@UsedByGodot
	public void setAgeRestrictedUser(@NonNull final Boolean isAgeRestrictedUser) {
		YandexAds.setAgeRestricted(isAgeRestrictedUser);
	}

	@Override
	public View onMainCreate(Activity activity) {
		layout = new FrameLayout(activity);
		return layout;
	}

	@NonNull
	private BannerAdSize getAdSize(int width, int height) {
		if (width > 0 && height > 0) {
			return BannerAdSize.inline(activity, width, height);
		}
		DisplayMetrics displayMetrics = activity.getResources().getDisplayMetrics();
		int adWidthPixels = layout != null && layout.getWidth() > 0 ? layout.getWidth() : displayMetrics.widthPixels;
		if (Build.VERSION.SDK_INT >= 23 && layout != null && layout.getRootWindowInsets() != null) {
			WindowInsets insets = layout.getRootWindowInsets();
			adWidthPixels -= insets.getSystemWindowInsetLeft() + insets.getSystemWindowInsetRight();
		}
		int adWidth = Math.max(1, Math.round(adWidthPixels / displayMetrics.density));
		bannerWidthDp = adWidth;
		return BannerAdSize.sticky(activity, adWidth);
	}

	@NonNull
	private AdRequest bannerRequest(@NonNull final String id) {
		return new AdRequest.Builder(id).build();
	}

	@NonNull
	private BannerAdView initBanner(final String id, final boolean isOnTop, int width, int height) {
		layout = (FrameLayout) activity.getWindow().getDecorView().getRootView();
		adParams = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT);
		adParams.gravity = (isOnTop ? Gravity.TOP : Gravity.BOTTOM) | Gravity.CENTER_HORIZONTAL;

		BannerAdView bannerAdView = new BannerAdView(activity);
		bannerAdView.setBackgroundColor(Color.TRANSPARENT);
		BannerAdSize size = getAdSize(width, height);
		bannerWidthPixels = size.getWidthInPixels(activity);
		bannerHeightPixels = size.getHeightInPixels(activity);
		bannerAdView.setAdSize(size);
		// Loading is invisible until the Godot manager confirms the menu is still open.
		bannerAdView.setVisibility(View.GONE);
		bannerAdView.setOnApplyWindowInsetsListener((view, insets) -> {
			if (Build.VERSION.SDK_INT >= 30) {
				Insets bars = insets.getInsets(WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout());
				adParams.bottomMargin = isOnTop ? 0 : bars.bottom;
				adParams.topMargin = isOnTop ? bars.top : 0;
				adParams.leftMargin = bars.left;
				adParams.rightMargin = bars.right;
			} else {
				adParams.bottomMargin = isOnTop ? 0 : insets.getSystemWindowInsetBottom();
				adParams.topMargin = isOnTop ? insets.getSystemWindowInsetTop() : 0;
				adParams.leftMargin = insets.getSystemWindowInsetLeft();
				adParams.rightMargin = insets.getSystemWindowInsetRight();
			}
			view.setLayoutParams(adParams);
			return insets;
		});
		bannerAdView.setBannerAdEventListener(createBannerAdEventListener());

		layout.addView(bannerAdView, adParams);
		bannerAdView.requestApplyInsets();
		bannerAdView.loadAd(bannerRequest(id));
		return bannerAdView;
	}

	private BannerAdEventListener createBannerAdEventListener() {
		return new BannerAdEventListener() {
			@Override
			public void onAdLoaded() {
				Log.w("godot", "YandexAds: onBannerAdLoaded");
				emitSignal("_on_banner_loaded");
			}

			@Override
			public void onAdFailedToLoad(@NonNull final AdRequestError error) {
				Log.w("godot", "YandexAds: onBannerAdFailedToLoad. Error: " + error.getCode());
				emitSignal("_on_banner_failed_to_load", error.getCode());
			}

			@Override
			public void onAdClicked() {
				Log.w("godot", "YandexAds: onBannerAdClicked");
				emitSignal("_on_banner_clicked");
			}

			@Override
			public void onImpression(@Nullable ImpressionData impressionData) {
			}
		};
	}

	@UsedByGodot
	public void loadBanner(final String id, final boolean isOnTop, int width, int height) {
		activity.runOnUiThread(() -> {
			DisplayMetrics metrics = activity.getResources().getDisplayMetrics();
			int currentWidthDp = Math.round(metrics.widthPixels / metrics.density);
			if (bannerAdView != null && Math.abs(currentWidthDp - bannerWidthDp) > 8) {
				layout.removeView(bannerAdView);
				bannerAdView.destroy();
				bannerAdView = null;
			}
			if (bannerAdView == null) {
				bannerAdView = initBanner(id, isOnTop, width, height);
			} else {
				bannerAdView.loadAd(bannerRequest(id));
				Log.w("godot", "YandexAds: Banner already created: " + id);
			}
		});
	}

	@UsedByGodot
	public int getBannerWidth() { return bannerWidthPixels; }

	@UsedByGodot
	public int getBannerHeight() { return bannerHeightPixels; }

	@UsedByGodot
	public void showBanner() {
		activity.runOnUiThread(() -> {
			if (bannerAdView != null) {
				bannerAdView.setVisibility(View.VISIBLE);
				Log.d("godot", "YandexAds: Show Banner");
			} else {
				Log.w("godot", "YandexAds: Banner not found");
			}
		});
	}

	@UsedByGodot
	public void removeBanner() {
		activity.runOnUiThread(() -> {
			if (layout == null || adParams == null) {
				return;
			}

			if (bannerAdView != null) {
				layout.removeView(bannerAdView);
				Log.d("godot", "YandexAds: Remove Banner");
			} else {
				Log.w("godot", "YandexAds: Banner not found");
			}
		});
	}

	@UsedByGodot
	public void hideBanner() {
		activity.runOnUiThread(() -> {
			if (bannerAdView != null) {
				bannerAdView.setVisibility(View.GONE);
				Log.d("godot", "YandexAds: Hide Banner");
			} else {
				Log.w("godot", "YandexAds: Banner not found");
			}
		});
	}

	private void loadRewardedVideoInternal(final String id) {
		RewardedAdLoader rewardedAdLoader = new RewardedAdLoader(activity);
		rewardedAdLoader.loadAd(new AdRequest.Builder(id).build(), new RewardedAdLoadListener() {
			@Override
			public void onAdLoaded(@NonNull RewardedAd newRewardedAd) {
				rewardedAd = newRewardedAd;
				Log.w("godot", "YandexAds: onRewardedVideoAdLoaded");
				emitSignal("_on_rewarded_video_ad_loaded");
			}

			@Override
			public void onAdFailedToLoad(@NonNull AdRequestError adRequestError) {
				Log.w("godot", "YandexAds: onRewardedVideoAdFailedToLoad. Error: " + adRequestError.getCode());
				emitSignal("_on_rewarded_video_ad_failed_to_load", adRequestError.getCode());
			}
		});
	}

	@UsedByGodot
	public void loadRewardedVideo(final String id) {
		activity.runOnUiThread(() -> {
			try {
				loadRewardedVideoInternal(id);
			} catch (Exception e) {
				Log.e("godot", e.toString());
			}
		});
	}

	@UsedByGodot
	public void showRewardedVideo() {
		activity.runOnUiThread(() -> {
			if (rewardedAd != null) {
				rewardedAd.setAdEventListener(createRewardedAdEventListener());
				rewardedAd.show(activity);
			}
		});
	}

	private RewardedAdEventListener createRewardedAdEventListener() {
		return new RewardedAdEventListener() {
			@Override
			public void onAdShown() {
				Log.w("godot", "YandexAds: onRewardedVideoAdShown");
				emitSignal("_on_rewarded_video_ad_show");
			}

			@Override
			public void onAdFailedToShow(@NonNull AdError adError) {
				Log.w("godot", "YandexAds: onRewardedVideoAdFailedToShown. Error: " + adError.getDescription());
				emitSignal("_on_rewarded_video_ad_failed_to_show", adError.getDescription());
			}

			@Override
			public void onAdDismissed() {
				Log.w("godot", "YandexAds: onRewardedVideoAdDismissed");
				emitSignal("_on_rewarded_video_ad_dismissed");
			}

			@Override
			public void onAdClicked() {
				Log.w("godot", "YandexAds: onRewardedVideoAdClicked");
				emitSignal("_on_rewarded_video_ad_clicked");
			}

			@Override
			public void onAdImpression(@Nullable ImpressionData impressionData) {
			}

			@Override
			public void onRewarded(@NonNull Reward reward) {
				Log.w("godot", "YandexAds: " + String.format("onRewarded! currency: %s amount: %d", reward.getType(), reward.getAmount()));
				emitSignal("_on_rewarded", reward.getType(), reward.getAmount());
			}
		};
	}

	private void loadInterstitialInternal(final String id) {
		InterstitialAdLoader interstitialAdLoader = new InterstitialAdLoader(activity);
		interstitialAdLoader.loadAd(new AdRequest.Builder(id).build(), new InterstitialAdLoadListener() {
			@Override
			public void onAdLoaded(@NonNull InterstitialAd newInterstitialAd) {
				interstitialAd = newInterstitialAd;
				Log.w("godot", "YandexAds: onInterstitialAdLoaded");
				emitSignal("_on_interstitial_loaded");
			}

			@Override
			public void onAdFailedToLoad(@NonNull AdRequestError adRequestError) {
				Log.w("godot", "YandexAds: onInterstitialAdFailedToLoad. Error: " + adRequestError.getCode());
				emitSignal("_on_interstitial_failed_to_load", adRequestError.getCode());
			}
		});
	}

	@UsedByGodot
	public void loadInterstitial(final String id) {
		activity.runOnUiThread(() -> {
			try {
				loadInterstitialInternal(id);
			} catch (Exception e) {
				Log.e("godot", e.toString());
			}
		});
	}

	@UsedByGodot
	public void showInterstitial() {
		activity.runOnUiThread(() -> {
			if (interstitialAd != null) {
				interstitialAd.setAdEventListener(createInterstitialAdEventListener());
				interstitialAd.show(activity);
			}
		});
	}

	private InterstitialAdEventListener createInterstitialAdEventListener() {
		return new InterstitialAdEventListener() {
			@Override
			public void onAdShown() {
				Log.w("godot", "YandexAds: onInterstitialAdShown");
				emitSignal("_on_interstitial_ad_show");
			}

			@Override
			public void onAdFailedToShow(@NonNull final AdError adError) {
				Log.w("godot", "YandexAds: onInterstitialAdFailedToShown. Error: " + adError.getDescription());
				emitSignal("_on_interstitial_failed_to_show", adError.getDescription());
			}

			@Override
			public void onAdDismissed() {
				Log.w("godot", "YandexAds: onInterstitialAdDismissed");
				emitSignal("_on_interstitial_ad_dismissed");
			}

			@Override
			public void onAdClicked() {
				Log.w("godot", "YandexAds: onInterstitialAdClicked");
				emitSignal("_on_interstitial_clicked");
			}

			@Override
			public void onAdImpression(@Nullable final ImpressionData impressionData) {
			}
		};
	}

	private void loadAppOpenInternal(final String id) {
		AppOpenAdLoader appOpenAdLoader = new AppOpenAdLoader(activity);
		appOpenAdLoader.loadAd(new AdRequest.Builder(id).build(), new AppOpenAdLoadListener() {
			@Override
			public void onAdLoaded(@NonNull AppOpenAd newAppOpenAd) {
				appOpenAd = newAppOpenAd;
				Log.w("godot", "YandexAds: onAppOpenAdLoaded");
				emitSignal("_on_app_open_ad_loaded");
			}

			@Override
			public void onAdFailedToLoad(@NonNull AdRequestError adRequestError) {
				Log.w("godot", "YandexAds: onAppOpenAdFailedToLoad. Error: " + adRequestError.getCode());
				emitSignal("_on_app_open_ad_failed_to_load", adRequestError.getCode());
			}
		});
	}

	@UsedByGodot
	public void loadAppOpen(final String id) {
		activity.runOnUiThread(() -> {
			try {
				loadAppOpenInternal(id);
			} catch (Exception e) {
				Log.e("godot", e.toString());
			}
		});
	}

	@UsedByGodot
	public void showAppOpen() {
		activity.runOnUiThread(() -> {
			if (appOpenAd != null) {
				AppOpenAd ad = appOpenAd;
				appOpenAd = null;
				ad.setAdEventListener(createAppOpenAdEventListener());
				ad.show(activity);
			} else {
				Log.w("godot", "YandexAds: App Open not loaded");
				emitSignal("_on_app_open_ad_failed_to_show", "not loaded");
			}
		});
	}

	private AppOpenAdEventListener createAppOpenAdEventListener() {
		return new AppOpenAdEventListener() {
			@Override
			public void onAdShown() {
				Log.w("godot", "YandexAds: onAppOpenAdShown");
				emitSignal("_on_app_open_ad_show");
			}

			@Override
			public void onAdFailedToShow(@NonNull final AdError adError) {
				Log.w("godot", "YandexAds: onAppOpenAdFailedToShown. Error: " + adError.getDescription());
				emitSignal("_on_app_open_ad_failed_to_show", adError.getDescription());
			}

			@Override
			public void onAdDismissed() {
				Log.w("godot", "YandexAds: onAppOpenAdDismissed");
				emitSignal("_on_app_open_ad_dismissed");
			}

			@Override
			public void onAdClicked() {
				Log.w("godot", "YandexAds: onAppOpenAdClicked");
				emitSignal("_on_app_open_ad_clicked");
			}

			@Override
			public void onAdImpression(@Nullable final ImpressionData impressionData) {
			}
		};
	}
}
