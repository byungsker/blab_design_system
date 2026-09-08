"use client";

import type { HTMLAttributes, ReactNode } from "react";

export const BLabSnackbarType = {
  success: "success",
  error: "error",
  info: "info",
  warning: "warning",
} as const;

export type BLabSnackbarType = (typeof BLabSnackbarType)[keyof typeof BLabSnackbarType];

type BLabSnackbarBaseProps = Omit<HTMLAttributes<HTMLDivElement>, "children" | "role"> & {
  readonly message: string;
  readonly type?: BLabSnackbarType;
  readonly icon?: ReactNode;
  readonly role?: "status" | "alert";
};

export type BLabSnackbarProps = BLabSnackbarBaseProps &
  (
    | { readonly onDismiss?: undefined; readonly dismissLabel?: string }
    | { readonly onDismiss: () => void; readonly dismissLabel: string }
  );

export function BLabSnackbar({
  message,
  type = BLabSnackbarType.success,
  icon,
  onDismiss,
  dismissLabel,
  role,
  className,
  ...rest
}: BLabSnackbarProps) {
  const snackbarClassName = ["blab-snackbar", `blab-snackbar--${type}`, className ?? ""]
    .filter(Boolean)
    .join(" ");
  const marker = type === "success" ? "✓" : type === "error" ? "!" : type === "warning" ? "!" : "i";
  const resolvedRole = role ?? (type === "error" ? "alert" : "status");

  return (
    <div
      {...rest}
      className={snackbarClassName}
      role={resolvedRole}
      aria-live={resolvedRole === "alert" ? "assertive" : "polite"}
      data-blab-component="snackbar"
    >
      <span className="blab-snackbar__icon" aria-hidden="true">{icon ?? marker}</span>
      <span className="blab-snackbar__message">{message}</span>
      {onDismiss && dismissLabel ? (
        <button className="blab-snackbar__dismiss" type="button" aria-label={dismissLabel} onClick={onDismiss}>
          ×
        </button>
      ) : null}
    </div>
  );
}
