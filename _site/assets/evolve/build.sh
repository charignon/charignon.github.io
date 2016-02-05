for f in *.dot; do
  dot $f -o ${f}.svg -Tsvg
done;
