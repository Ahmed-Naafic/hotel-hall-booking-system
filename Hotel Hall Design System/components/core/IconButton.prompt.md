Icon-only control for toolbars, gallery arrows and card actions.

```jsx
<IconButton icon={<Icon name="heart" />} label="Save room" variant="outline" />
<IconButton icon={<Icon name="chevron-right" />} label="Next photo" variant="glass" round />
```

Use `glass` only over photography. Always pass `label` — it becomes the accessible name and the tooltip.
