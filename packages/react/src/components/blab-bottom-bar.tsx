"use client";

import { useEffect, useRef, useState } from "react";
import type { CSSProperties, PointerEvent, ReactNode } from "react";

import { BLabMotion } from "../tokens.js";

export type BLabBottomBarItem = {
  readonly icon: ReactNode;
  readonly activeIcon: ReactNode;
  readonly label: string;
};

type BLabBottomBarBaseProps = {
  readonly tabs: readonly BLabBottomBarItem[];
  readonly selectedIndex: number;
  readonly onTabSelected: (index: number) => void;
  readonly noMargin?: boolean;
  readonly ariaLabel: string;
  readonly className?: string;
};

type BLabBottomBarSearchProps =
  | { readonly onSearchTap?: undefined; readonly actionIcon?: ReactNode; readonly actionLabel?: string }
  | { readonly onSearchTap: () => void; readonly actionIcon?: ReactNode; readonly actionLabel: string };

type BLabBottomBarChevronProps =
  | {
      readonly showFirstTabChevron?: false;
      readonly onFirstTabChevronTap?: () => void;
      readonly firstTabChevronLabel?: string;
    }
  | {
      readonly showFirstTabChevron: true;
      readonly onFirstTabChevronTap: () => void;
      readonly firstTabChevronLabel: string;
    };

export type BLabBottomBarProps = BLabBottomBarBaseProps & BLabBottomBarSearchProps & BLabBottomBarChevronProps;

export function BLabBottomBar({
  tabs,
  selectedIndex,
  onTabSelected,
  onSearchTap,
  actionIcon,
  actionLabel,
  showFirstTabChevron = false,
  onFirstTabChevronTap,
  firstTabChevronLabel,
  noMargin = false,
  ariaLabel,
  className,
}: BLabBottomBarProps) {
  const itemsRef = useRef<HTMLDivElement>(null);
  const pressRef = useRef<{
    pointerId: number;
    active: boolean;
    timer: ReturnType<typeof setTimeout>;
  } | undefined>(undefined);
  const suppressClickRef = useRef(false);
  const [isDragging, setIsDragging] = useState(false);
  const [dragIndex, setDragIndex] = useState(selectedIndex);

  useEffect(() => {
    if (!isDragging) {
      setDragIndex(selectedIndex);
    }
  }, [isDragging, selectedIndex]);

  useEffect(() => () => {
    if (pressRef.current) {
      clearTimeout(pressRef.current.timer);
    }
  }, []);

  const clampIndex = (index: number) => Math.max(0, Math.min(tabs.length - 1, index));

  const indexFromClientX = (clientX: number) => {
    const bounds = itemsRef.current?.getBoundingClientRect();
    if (!bounds || tabs.length === 0) {
      return selectedIndex;
    }

    const inset = 4;
    const usableWidth = Math.max(bounds.width - inset * 2, 1);
    return clampIndex(Math.floor(((clientX - bounds.left - inset) / usableWidth) * tabs.length));
  };

  const stopPointerPress = () => {
    if (pressRef.current) {
      clearTimeout(pressRef.current.timer);
      pressRef.current = undefined;
    }
  };

  const handlePointerDown = (event: PointerEvent<HTMLDivElement>) => {
    if (event.button !== 0 || tabs.length === 0) {
      return;
    }

    const target = event.target;
    if (target instanceof Element && target.closest(".blab-bottom-bar__chevron")) {
      return;
    }

    event.currentTarget.setPointerCapture(event.pointerId);
    const press = {
      pointerId: event.pointerId,
      active: false,
      timer: setTimeout(() => {
        press.active = true;
        setIsDragging(true);
        setDragIndex(selectedIndex);
      }, BLabMotion.longPressDelay),
    };
    pressRef.current = press;
  };

  const handlePointerMove = (event: PointerEvent<HTMLDivElement>) => {
    const press = pressRef.current;
    if (!press || press.pointerId !== event.pointerId || !press.active) {
      return;
    }

    setDragIndex(indexFromClientX(event.clientX));
  };

  const handlePointerUp = (event: PointerEvent<HTMLDivElement>) => {
    const press = pressRef.current;
    if (!press || press.pointerId !== event.pointerId) {
      return;
    }

    const wasDragging = press.active;
    const nextIndex = indexFromClientX(event.clientX);
    stopPointerPress();
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }

    if (!wasDragging) {
      return;
    }

    setIsDragging(false);
    setDragIndex(nextIndex);
    suppressClickRef.current = true;
    setTimeout(() => {
      suppressClickRef.current = false;
    }, 0);
    if (nextIndex !== selectedIndex) {
      onTabSelected(nextIndex);
    }
  };

  const handlePointerCancel = (event: PointerEvent<HTMLDivElement>) => {
    const press = pressRef.current;
    if (!press || press.pointerId !== event.pointerId) {
      return;
    }

    stopPointerPress();
    setIsDragging(false);
    setDragIndex(selectedIndex);
  };

  const handleTabClick = (index: number) => {
    if (suppressClickRef.current) {
      suppressClickRef.current = false;
      return;
    }

    onTabSelected(index);
  };

  const indicatorIndex = isDragging ? dragIndex : selectedIndex;
  const indicatorStyle = {
    "--blab-bottom-bar-indicator-position": indicatorIndex,
    "--blab-bottom-bar-tab-count": tabs.length,
  } as CSSProperties & {
    readonly "--blab-bottom-bar-indicator-position": number;
    readonly "--blab-bottom-bar-tab-count": number;
  };
  const barClassName = [
    "blab-bottom-bar",
    noMargin ? "blab-bottom-bar--no-margin" : "",
    className ?? "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <nav className={barClassName} aria-label={ariaLabel}>
      <div
        className="blab-bottom-bar__items"
        ref={itemsRef}
        style={indicatorStyle}
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        onPointerCancel={handlePointerCancel}
      >
        <span className="blab-bottom-bar__indicator" data-blab-dragging={isDragging || undefined} aria-hidden="true" />
        {tabs.map((tab, index) => {
          const selected = index === selectedIndex;
          const highlighted = index === indicatorIndex;
          return (
            <div
              key={`${tab.label}-${index}`}
              className="blab-bottom-bar__item-wrap"
            >
              <button
                className="blab-bottom-bar__item"
                type="button"
                aria-current={selected ? "page" : undefined}
                onClick={() => handleTabClick(index)}
              >
                <span aria-hidden="true">{highlighted ? tab.activeIcon : tab.icon}</span>
                <span>{tab.label}</span>
              </button>
              {showFirstTabChevron && index === 0 && onFirstTabChevronTap && firstTabChevronLabel ? (
                <button
                  className="blab-bottom-bar__chevron"
                  type="button"
                  aria-label={firstTabChevronLabel}
                  onClick={onFirstTabChevronTap}
                >
                  ⌄
                </button>
              ) : null}
            </div>
          );
        })}
      </div>
      {onSearchTap && actionLabel ? (
        <button className="blab-bottom-bar__action" type="button" aria-label={actionLabel} onClick={onSearchTap}>
          <span aria-hidden="true">{actionIcon ?? "⌕"}</span>
        </button>
      ) : null}
    </nav>
  );
}
