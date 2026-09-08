"use client";

import { useRef } from "react";
import type { CSSProperties, KeyboardEventHandler } from "react";

type BLabTabBarStyle = CSSProperties & {
  readonly "--blab-tab-indicator-color": string;
  readonly "--blab-tab-indicator-weight": string;
  readonly "--blab-tab-label-color": string;
  readonly "--blab-tab-unselected-color": string;
};

export type BLabTabBarProps = {
  readonly tabs: readonly string[];
  readonly selectedIndex: number;
  readonly onTabSelected: (index: number) => void;
  readonly indicatorColor?: string;
  readonly labelColor?: string;
  readonly unselectedLabelColor?: string;
  readonly indicatorWeight?: number;
  readonly isScrollable?: boolean;
  readonly ariaLabel: string;
  readonly className?: string;
};

export function BLabTabBar({
  tabs,
  selectedIndex,
  onTabSelected,
  indicatorColor,
  labelColor,
  unselectedLabelColor,
  indicatorWeight = 3,
  isScrollable = false,
  ariaLabel,
  className,
}: BLabTabBarProps) {
  const tabRefs = useRef<Array<HTMLButtonElement | null>>([]);

  const handleKeyDown: KeyboardEventHandler<HTMLButtonElement> = (event) => {
    if (tabs.length === 0) {
      return;
    }

    const nextIndex =
      event.key === "ArrowRight"
        ? (selectedIndex + 1) % tabs.length
        : event.key === "ArrowLeft"
          ? (selectedIndex - 1 + tabs.length) % tabs.length
          : event.key === "Home"
            ? 0
            : event.key === "End"
              ? tabs.length - 1
              : undefined;

    if (nextIndex === undefined) {
      return;
    }

    event.preventDefault();
    onTabSelected(nextIndex);
    requestAnimationFrame(() => tabRefs.current[nextIndex]?.focus());
  };

  const style: BLabTabBarStyle = {
    "--blab-tab-indicator-color": indicatorColor ?? "var(--blab-text-primary)",
    "--blab-tab-indicator-weight": `${indicatorWeight}px`,
    "--blab-tab-label-color": labelColor ?? "var(--blab-text-primary)",
    "--blab-tab-unselected-color": unselectedLabelColor ?? "var(--blab-text-tertiary)",
  };
  const tabBarClassName = [
    "blab-tab-bar",
    isScrollable ? "blab-tab-bar--scrollable" : "",
    className ?? "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div className={tabBarClassName} role="tablist" aria-label={ariaLabel} style={style}>
      {tabs.map((tab, index) => (
        <button
          key={`${tab}-${index}`}
          className="blab-tab-bar__tab"
          type="button"
          role="tab"
          aria-selected={index === selectedIndex}
          tabIndex={index === selectedIndex ? 0 : -1}
          ref={(element) => {
            tabRefs.current[index] = element;
          }}
          onClick={() => onTabSelected(index)}
          onKeyDown={handleKeyDown}
        >
          {tab}
        </button>
      ))}
    </div>
  );
}
