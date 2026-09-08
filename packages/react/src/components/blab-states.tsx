"use client";

import type { ReactNode } from "react";

import { BLabButton } from "./blab-button.js";

export type BLabLoadingStateProps = {
  readonly label: string;
  readonly size?: "small" | "medium" | "large";
  readonly className?: string;
};

export function BLabLoadingState({
  label,
  size = "medium",
  className,
}: BLabLoadingStateProps) {
  return (
    <div className={["blab-loading-state", className ?? ""].filter(Boolean).join(" ")} role="status" aria-live="polite">
      <span
        className={["blab-loading-state__spinner", `blab-loading-state__spinner--${size}`].join(" ")}
        aria-hidden="true"
      />
      <span>{label}</span>
    </div>
  );
}

export type BLabEmptyStateProps = {
  readonly title: string;
  readonly message?: string;
  readonly icon?: ReactNode;
  readonly actionLabel?: string;
  readonly onAction?: () => void;
  readonly className?: string;
};

export function BLabEmptyState({
  title,
  message,
  icon,
  actionLabel,
  onAction,
  className,
}: BLabEmptyStateProps) {
  return (
    <div className={["blab-empty-state", className ?? ""].filter(Boolean).join(" ")} role="status">
      {icon ? <span className="blab-empty-state__icon" aria-hidden="true">{icon}</span> : null}
      <strong className="blab-empty-state__title">{title}</strong>
      {message ? <span className="blab-empty-state__message">{message}</span> : null}
      {actionLabel && onAction ? (
        <BLabButton text={actionLabel} variant="secondary" onClick={onAction} />
      ) : null}
    </div>
  );
}

export type BLabRetryButtonProps = {
  readonly label: string;
  readonly onClick: () => void;
  readonly loading?: boolean;
  readonly disabled?: boolean;
  readonly className?: string;
};

export function BLabRetryButton({
  label,
  onClick,
  loading = false,
  disabled = false,
  className,
}: BLabRetryButtonProps) {
  return (
    <BLabButton
      className={className}
      text={label}
      variant="secondary"
      onClick={onClick}
      loading={loading}
      disabled={disabled}
    />
  );
}

export type BLabErrorStateProps = {
  readonly title: string;
  readonly message: string;
  readonly icon?: ReactNode;
  readonly retryLabel?: string;
  readonly onRetry?: () => void;
  readonly retryLoading?: boolean;
  readonly className?: string;
};

export function BLabErrorState({
  title,
  message,
  icon,
  retryLabel,
  onRetry,
  retryLoading = false,
  className,
}: BLabErrorStateProps) {
  return (
    <div className={["blab-error-state", className ?? ""].filter(Boolean).join(" ")} role="alert">
      {icon ? <span className="blab-error-state__icon" aria-hidden="true">{icon}</span> : null}
      <strong className="blab-error-state__title">{title}</strong>
      <span className="blab-error-state__message">{message}</span>
      {retryLabel && onRetry ? (
        <BLabRetryButton label={retryLabel} onClick={onRetry} loading={retryLoading} />
      ) : null}
    </div>
  );
}
